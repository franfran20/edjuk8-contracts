// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// course handler function allows:
//   users to register on the platform
//   deploys course contract NFTs
//   deploys course ERC20 token shares with a fixed supply

import {ICourseHandler} from "./interfaces/ICourseHandler.sol";
import {IShareMarketPlace} from "./interfaces/IShareMarketPlace.sol";
import {ISubCourseDeployer} from "./interfaces/ISubCourseDeployer.sol";
import {Types} from "./utils/Types.sol";
import {MetaTx} from "./utils/MetaTx.sol";
import {Errors} from "./utils/Errors.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CourseHandler is ICourseHandler, ReentrancyGuard, EIP712 {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    Types.Course[] allCourses;
    IShareMarketPlace shareMarketPlace;
    IERC20 edjuk8Token;
    ISubCourseDeployer subCourseDeployer;

    uint256 public constant CREATION_SHARE = 100e4;
    uint256 constant MAX_USERNAME_CHAR = 21;
    string constant BASE_COURSE_URI = "https://edjuk8-stuff/learn/courses/";

    uint256 public courseIds;
    uint256 courseCreationFee;
    uint256 MAX_ALLOWED_COURSES = 8;
    uint256 MAX_ALLOWED_SUB_COURSE = 8;
    uint256 MAX_PRICE = 100e18;
    uint256 public MIN_SHARE_OWNER_MUST_HOLD = 30e4;

    address dev;

    mapping(address => Types.User) _user;
    mapping(string username => bool taken) _usernameTaken;

    mapping(address user => mapping(uint256 courseId => uint256 shares)) _userCourseShares;
    mapping(address user => mapping(uint256 courseId => uint256 shares)) _userSharesLocked;
    mapping(address user => mapping(uint256 courseId => bool shareHolder)) _isShareHolder;

    mapping(address user => mapping(uint256 courseId => uint256 listingId)) _userActiveCourseListingId;

    modifier courseMustExist(uint256 courseId) {
        require(courseId <= courseIds, "Non Existent Course");
        _;
    }

    modifier onlyDev() {
        require(msg.sender == dev, "!dev");
        _;
    }

    constructor(address edjuk8TokenAddress) EIP712("Course Handler", "1") {
        dev = msg.sender;
        edjuk8Token = IERC20(edjuk8TokenAddress);
    }

    //////// ADMIN FUNCTIONS ////////

    // set the market place contract addr
    function setCourseMarketPlace(address _shareMarketPlace) external onlyDev {
        shareMarketPlace = IShareMarketPlace(_shareMarketPlace);
    }

    // set the subCourse deployer
    function setSubCourseDeployer(address subCourseDeployerAddress) external onlyDev {
        subCourseDeployer = ISubCourseDeployer(subCourseDeployerAddress);
    }

    // set the course creation fee if needed
    function setCourseCreationFee(uint256 fee) external onlyDev {
        courseCreationFee = fee;
    }

    //////// USER FUNCTIONS ////

    // register
    function registerUser(Types.Register memory params) external {
        _registerUser(msg.sender, params.username);
    }

    // register with sig
    function registerUserWithSig(Types.RegisterWithSig memory params) external {
        _user[params.user].nonce++;

        bytes32 structHash = MetaTx._registerStructHash(params, _user[params.user].nonce);
        _checkIsSigner(structHash, params.v, params.r, params.s, params.user);

        _registerUser(params.user, params.username);
    }

    // create course
    function createCourse(Types.CreateCourse memory params) external {
        _createCourse(params.name, params.description, params.imageURI, params.genre, msg.sender);
    }

    // create course with sig
    function createCourseWithSig(Types.CreateCourseWithSig memory params) external {
        _user[params.user].nonce++;

        bytes32 structHash = MetaTx._createCourseStructHash(params, _user[params.user].nonce);
        _checkIsSigner(structHash, params.v, params.r, params.s, params.user);

        _createCourse(params.name, params.description, params.imageURI, params.genre, params.user);
    }

    // sell course share
    function sellCourseShare(Types.SellShare memory params) external nonReentrant courseMustExist(params.courseId) {
        _sellCourseShare(params.courseId, params.sharesAmount, params.price, msg.sender);
    }

    // sell course share with sig
    function sellCourseShareWithSig(Types.SellShareWIthSig memory params)
        external
        nonReentrant
        courseMustExist(params.courseId)
    {
        _user[params.user].nonce++;

        bytes32 structHash = MetaTx._sellSharesStructHash(params, _user[params.user].nonce);
        _checkIsSigner(structHash, params.v, params.r, params.s, params.user);

        _sellCourseShare(params.courseId, params.sharesAmount, params.price, params.user);
    }

    // cash in course shares
    function cashInCourseShares(Types.CashInCourseShare memory params)
        external
        courseMustExist(params.courseId)
        nonReentrant
    {
        _cashInCourseShares(params.courseId, params.sharesAmount, msg.sender);
    }

    // cashin course shares with sig
    function cashInCourseSharesWithSig(Types.CashInCourseShareWithSig memory params)
        external
        courseMustExist(params.courseId)
        nonReentrant
    {
        _user[params.user].nonce++;

        bytes32 structHash = MetaTx._cashInCourseShareStructHash(params, _user[params.user].nonce);
        _checkIsSigner(structHash, params.v, params.r, params.s, params.user);

        _cashInCourseShares(params.courseId, params.sharesAmount, params.user);
    }

    ////////// ONLY CALLABLE BY SHARE MARKET PLACE //////////

    // after a successful purchase from the buyer in the marketplace
    function shareUpdate(address seller, address buyer, uint256 courseId, uint256 sharesAmount) external nonReentrant {
        require(msg.sender == address(shareMarketPlace), "!marketPlace");
        _userSharesLocked[seller][courseId] = 0;
        _userCourseShares[buyer][courseId] += sharesAmount;
        _userActiveCourseListingId[seller][courseId] = 0;

        _updateShareHolders(seller, buyer, courseId, sharesAmount);
    }

    /// ONLY CALLABLE BY THE SUBCOURSE OF A COURSE ///////
    function updateSubCourseEnrollment(uint256 courseId, uint256 enrollmentPrice) external courseMustExist(courseId) {
        bool callerAllowed = _checkCallerIsASubCourseForTheCourseId(courseId);
        if (!callerAllowed) revert Errors.Edjuk8__CallerIsNotSubCourse();

        // that it updates the share earnings and user earnings with the right percentage of their current share
        uint256 courseIndex = courseId - 1;
        address owner = allCourses[courseIndex].owner;

        // ((shares / 1e4 ) * enrollMentPrice / 100) == ((shares * enrollmentPrice) / 100e4)
        uint256 ownerShare = _userCourseShares[owner][courseId];
        uint256 shareHolders = CREATION_SHARE - ownerShare;

        allCourses[courseIndex].courseEarnings += ((ownerShare * enrollmentPrice) / (100e4));
        allCourses[courseIndex].shareEarnings += ((shareHolders * enrollmentPrice) / (100e4));
        allCourses[courseIndex].studentsEnrolled += 1;
    }

    // ONLY CALLABLE BY SUBCOURSE DEPLOYER

    //////// UPDATE FUNCTIONS //////

    // // manages share holder count on transfereence of shares between users
    function _updateShareHolders(address from, address to, uint256 courseId, uint256 sharesAmount) internal {
        uint256 courseIndex = courseId - 1;

        // seller sold his last share
        if (_userCourseShares[from][courseId] == 0) {
            _isShareHolder[from][courseId] = false;
            allCourses[courseIndex].shareHolders -= 1;
            _removeCourseFromOwnedCourses(from, courseId);
        }

        // first time receiving share
        if (_userCourseShares[to][courseId] == sharesAmount) {
            // implement: cannot have more than a certain number of courses
            if (_user[to].ownedCourses.length > MAX_ALLOWED_COURSES) {
                revert Errors.Edjuk8__UserMaxCourseExceeded();
            }

            if (!_isShareHolder[to][courseId]) {
                _isShareHolder[to][courseId] = true;
                allCourses[courseIndex].shareHolders += 1;

                Types.Course memory course = allCourses[courseIndex];
                _user[to].ownedCourses.push(course);
            }
        }
    }

    /////// HELPER FUNCTIONS //////
    function _checkCallerIsASubCourseForTheCourseId(uint256 courseId) internal view returns (bool) {
        Types.SubCourseDetail[] memory subCourses = subCourseDeployer.getSubCourses(courseId); // replace this line with getting teh subCourses from the subcourse deployer
        for (uint256 i = 0; i < subCourses.length; i++) {
            if (subCourses[i].subCourseAddress == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function _constructCourseURI(uint256 courseId) public pure returns (string memory) {
        return string.concat(BASE_COURSE_URI, courseId.toString());
    }

    // // WE WERE WORKING ON PUTTING USERS COURSES WITH SHARES INTO THE USERS OWNED COURSES LIST
    function _removeCourseFromOwnedCourses(address user, uint256 courseId) internal {
        uint256 ownedCoursesLength = _user[user].ownedCourses.length;
        bool found = false;

        for (uint256 i = 0; i < ownedCoursesLength; i++) {
            if (_user[user].ownedCourses[i].ID == courseId) {
                //
                _user[user].ownedCourses[i] = _user[user].ownedCourses[ownedCoursesLength - 1];
                found = true;
                _user[user].ownedCourses.pop();
                break;
            }
        }

        if (!found) revert Errors.Edjuk8__NotCourseOwner();
    }

    // /////// CORE LOGIC FUNCTIONS //////
    // Private Functions
    function _registerUser(address user, string memory username) private {
        if (_user[user].author) {
            revert Errors.Edjuk8__AlreadyRegistered();
        }
        if (bytes(username).length > MAX_USERNAME_CHAR) {
            revert Errors.Edjuk8__UsernameCharactersExceeded();
        }
        if (_usernameTaken[username]) revert Errors.Edjuk8__UsernameTaken();

        _user[user].username = username;
        _user[user].author = true;
        _usernameTaken[username] = true;
    }

    function _createCourse(
        string memory name,
        string memory description,
        string memory imageURI,
        uint8 genre,
        address user
    ) private {
        if (!_user[user].author) {
            revert Errors.Edjuk8__NotRegistered();
        }

        if (edjuk8Token.allowance(user, address(this)) < courseCreationFee) {
            revert Errors.Edjuk8__InsufficientTokenAllowance();
        }
        if (edjuk8Token.balanceOf(user) < courseCreationFee) {
            revert Errors.Edjuk8__InsuficientTokenBalance();
        }
        // implement: cannot have more than a certain number of courses
        if (_user[user].ownedCourses.length >= MAX_ALLOWED_COURSES) revert Errors.Edjuk8__UserMaxCourseExceeded();

        if (courseCreationFee > 0) {
            edjuk8Token.transferFrom(user, address(this), courseCreationFee);
        }

        courseIds++;
        uint256 courseId = courseIds;

        Types.Course memory course = Types.Course({
            name: name,
            description: description,
            imageURI: imageURI,
            courseURI: _constructCourseURI(courseId),
            ownerName: _user[user].username,
            owner: user,
            studentsEnrolled: 0,
            ID: courseId,
            courseEarnings: 0,
            shareEarnings: 0,
            shareHolders: 1,
            genre: genre
        });

        allCourses.push(course);
        _userCourseShares[user][courseId] = CREATION_SHARE;
        _isShareHolder[user][courseId] = true;

        _user[user].ownedCourses.push(course);
    }

    function _sellCourseShare(uint256 courseId, uint256 sharesAmount, uint256 price, address user) private {
        uint256 userShares = _userCourseShares[user][courseId];
        uint256 courseIndex = courseId - 1;

        address courseOwner = allCourses[courseIndex].owner;

        if (!_isShareHolder[user][courseId]) {
            revert Errors.Edjuk8__NotAShareHolder();
        }
        if (user == courseOwner) {
            if (_userCourseShares[user][courseId] - sharesAmount < MIN_SHARE_OWNER_MUST_HOLD) {
                revert Errors.Edjuk9__OwnerCantHaveLessThanMinimumPercentShare();
            }
        }
        if (sharesAmount == 0) {
            revert Errors.Edjuk8__SharesToSellCannotBeZero();
        }
        if (sharesAmount > userShares) {
            revert Errors.Edjuk8__InsufficentSharesBalance();
        }

        _userSharesLocked[user][courseId] = sharesAmount;
        _userCourseShares[user][courseId] -= sharesAmount;

        uint256 courseListingId =
            shareMarketPlace.sellShares({user: user, shareAmount: sharesAmount, courseId: courseId, price: price});

        _userActiveCourseListingId[user][courseId] = courseListingId;
    }

    function _cashInCourseShares(uint256 courseId, uint256 sharesAmount, address user) private {
        if (!_isShareHolder[user][courseId]) revert Errors.Edjuk8__UserIsNotAShareHolder();
        if (_userCourseShares[user][courseId] == 0) revert Errors.Edjuk8__UserHasZeroShares();
        if (_userCourseShares[user][courseId] < sharesAmount) revert Errors.Edjuk8__InsufficentSharesBalance();

        uint256 courseIndex = courseId - 1;
        Types.Course memory course = allCourses[courseIndex];

        if (sharesAmount == 0) revert Errors.SharesToCashInCannotBeZero();

        // check if the user is the owner
        if (user == course.owner) {
            require(course.courseEarnings > 0, "No balance");

            allCourses[courseIndex].courseEarnings = 0;

            edjuk8Token.safeTransfer(user, course.courseEarnings);
        } else {
            require(course.shareEarnings > 0, "No balance");
            // we cancel the user share listing on market place
            // giving them back their share

            // ---- I DONT THINK ITS NECESSARY TO CANCEL THEIR LISTING BECAUSE THE LISTING SHARE IS ALREADY LOCKED ----
            // uint256 userListingId = _userActiveCourseListingId[user][courseId];
            // if (userListingId > 0) {
            //     shareMarketPlace.canceShareListing(userListingId);
            //     _userActiveCourseListingId[user][courseId] = 0;
            // }
            // to get the % of the share amount

            uint256 totalShareHoldersShare = CREATION_SHARE - _userCourseShares[course.owner][courseId];
            uint256 cashInAmount = sharesAmount * course.shareEarnings / totalShareHoldersShare;

            allCourses[courseIndex].courseEarnings -= cashInAmount;
            _userCourseShares[user][courseId] -= sharesAmount;

            if (_userCourseShares[user][courseId] == 0) {
                _isShareHolder[user][courseId] = false;
                allCourses[courseIndex].shareHolders -= 1;
                _removeCourseFromOwnedCourses(user, courseId);
            }

            edjuk8Token.safeTransfer(user, cashInAmount);
        }
    }

    function _checkIsSigner(bytes32 structHash, uint8 v, bytes32 r, bytes32 s, address user) private view {
        address signer = ECDSA.recover(_hashTypedDataV4(structHash), v, r, s);
        if (signer != user) {
            revert Errors.Edjuk8__InvalidSigner();
        }
    }

    // }

    //////// GETTER FUNCTIONS ///////

    // // try8 and and add paginaion to each to fetch by index and stuff
    function getAllCourses() external view returns (Types.Course[] memory) {
        return allCourses;
    }

    // // // get coursse by Id
    function getCourseById(uint256 courseId) external view returns (Types.Course memory) {
        require(courseId > 0, "Invalid Course ID");
        uint256 courseIndex = courseId - 1;
        return allCourses[courseIndex];
    }

    // // get user owned courses
    function getUserOwnedCourses(address _owner) external view returns (Types.Course[] memory) {
        return _user[_owner].ownedCourses;
    }

    // user course share amount, their cash in amount
    function getUserCourseShareDetails(uint256 courseId, address user)
        external
        view
        returns (bool, uint256, uint256, uint256)
    {
        return (
            _isShareHolder[user][courseId],
            _userCourseShares[user][courseId],
            _userSharesLocked[user][courseId],
            _userActiveCourseListingId[user][courseId]
        );

        // WE MIGHT BE ABLE TO CALCULATE THIS IN THE FORNTEND

        // if (courseId > 0) {
        //     uint256 courseIndex = courseId - 1;
        //     uint256 userCourseShare = _userCourseShares[user][courseId];

        //     bool isOwner = user == allCourses[courseIndex].owner ? true : false;

        //     uint256 cashInAmount;
        //     if (isOwner) {
        //         cashInAmount = allCourses[courseIndex].courseEarnings;
        //         return (userCourseShare, cashInAmount);
        //     } else if (userCourseShare > 0) {
        //         uint256 cashInBalance = allCourses[courseIndex].shareEarnings;
        //         cashInAmount = userCourseShare * cashInBalance / 100e4;
        //         return (userCourseShare, cashInAmount);
        //     } else {
        //         return (0, 0);
        //     }
        // } else {
        //     revert Errors.Edjuk8__InvalidCourseId();
        // }
    }

    function getCourseIdCounter() external view returns (uint256) {
        return courseIds;
    }

    // get user details
    function getUserDetails(address user) external view returns (Types.User memory) {
        return _user[user];
    }

    function getTypedDataHash(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }
}
