// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Types} from "../src/utils/Types.sol";

import {CourseHandler} from "../src/CourseHandler.sol";
import {ShareMarketPlace} from "../src/ShareMarketPlace.sol";
import {SubCourseDeployer} from "../src/SubCourseDeployer.sol";
import {Edjuk8Token} from "../src/Edjuk8Token.sol";

import {ISubCourse} from "../src/interfaces/ISubCourse.sol";

contract BaseTest is Test {
    SubCourseDeployer subCourseDeployer;
    CourseHandler courseHandler;
    ShareMarketPlace shareMarketPlace;
    Edjuk8Token edjuk8Token;

    //    (address alice, uint256 key) = makeAddrAndKey("alice");

    //    ( address userOne, uint256 userOneKey) = makeAddr("userOne");
    //     (address userTwo, uint256 userTwoKey) = makeAddr("userThree");
    //    ( address userThree, uint256 userThreeKey) = makeAddr("userThree");

    string usernameOne = "Sterling";

    uint256 oneMinute = 60; //60 seconds

    string courseNameOne = "Course Name 1";
    string courseDescriptionOne = "Course Description 1";
    string imageURI = "https://my-image.jpg";
    uint8 softwareEng = 1;

    string lessonName = "Generic Lessson Name";
    string gatedLessonURI = "http://edjuk9-stuff/course/2/lesson/12";
    uint256 lessonLength = 12 minutes;

    // (string memory name, bool lessonType, string memory gatedLessonURI, uint256 lessonLength)

    //  struct DeploySubCourse {
    //     string name;
    //     string description;
    //     string imageURI;
    //     uint256 price;
    //     string focusAreas;
    //     uint256 courseId;
    // }

    string subCourseName = "Egg Sauce";
    string subCourseDescripton = "Dont you love Egg Sauce";
    string focusArea = "There's a new look in town. I hope you know what the new look looks like lol";

    function setUp() public {
        address deployer = makeAddr("Deployer");

        vm.startPrank(deployer);

        edjuk8Token = new Edjuk8Token();
        courseHandler = new CourseHandler(address(edjuk8Token));
        subCourseDeployer = new SubCourseDeployer(address(courseHandler), address(edjuk8Token));
        shareMarketPlace = new ShareMarketPlace(address(courseHandler), address(edjuk8Token));

        courseHandler.setCourseMarketPlace(address(shareMarketPlace));
        courseHandler.setSubCourseDeployer(address(subCourseDeployer));

        vm.stopPrank();
    }

    // Course Handler Test Actions

    function _registerUser(string memory username, address user) internal {
        Types.Register memory params = Types.Register(username);

        vm.startPrank(user);
        courseHandler.registerUser(params);
        vm.stopPrank();
    }

    function _createCourse(address user) internal {
        Types.CreateCourse memory params = Types.CreateCourse({
            name: courseNameOne,
            description: courseDescriptionOne,
            imageURI: imageURI,
            genre: softwareEng
        });

        vm.startPrank(user);
        courseHandler.createCourse(params);
        vm.stopPrank();
    }

    function _sellShare(uint256 courseId, uint256 sharesToSell, uint256 priceToSell, address user) internal {
        vm.startPrank(user);
        Types.SellShare memory params =
            Types.SellShare({courseId: courseId, sharesAmount: sharesToSell, price: priceToSell});
        courseHandler.sellCourseShare(params);
        vm.stopPrank();
    }

    function _cashInShares(uint256 courseId, uint256 sharesToCashIn, address user) internal {
        Types.CashInCourseShare memory params =
            Types.CashInCourseShare({courseId: courseId, sharesAmount: sharesToCashIn});

        vm.startPrank(user);
        courseHandler.cashInCourseShares(params);
        vm.stopPrank();
    }

    // Share Market Place

    function _buyShares(uint256 listingId, address user) internal {
        uint256 listingPrice = shareMarketPlace.getShareListingById(listingId).totalPrice;

        vm.startPrank(user);
        // mint and approve token
        edjuk8Token.mintFree(user, listingPrice);
        edjuk8Token.approve(address(shareMarketPlace), listingPrice);

        // buy shares
        shareMarketPlace.buyShares(listingId);
        vm.stopPrank();
    }

    function _cancelShareListing(uint256 listingId, address user) internal {
        vm.startPrank(user);
        // cancel share listing
        shareMarketPlace.canceShareListing(listingId);
        vm.stopPrank();
    }

    // Edjus 8 Token Test Helpers

    function _approveEdjuk8Token(address spender, uint256 value, address user) internal {
        vm.startPrank(user);
        edjuk8Token.approve(spender, value);
        vm.stopPrank();
    }

    function _mintEdjuk8Tokens(uint256 amount, address user) internal {
        vm.startPrank(user);
        edjuk8Token.mintFree(user, amount);
        vm.stopPrank();
    }

    // Sub Course Deployer

    function _createSubCourse(uint256 courseId, uint256 subCoursePrice, address user)
        internal
        returns (uint256 subCourseId, address subCourseAddres)
    {
        Types.DeploySubCourse memory params = Types.DeploySubCourse({
            name: subCourseName,
            description: subCourseDescripton,
            imageURI: imageURI,
            price: subCoursePrice,
            focusAreas: focusArea,
            courseId: courseId
        });

        vm.startPrank(user);
        (subCourseId, subCourseAddres) = subCourseDeployer.deploySubCourse(params);
        vm.stopPrank();
    }

    // SubCourse

    function _enroll(address subCourseAddress, uint256 subCoursePrice, address student) internal {
        ISubCourse subCourse = ISubCourse(subCourseAddress);

        _mintEdjuk8Tokens(subCoursePrice, student);
        _approveEdjuk8Token(subCourseAddress, subCoursePrice, student);

        vm.startPrank(student);
        subCourse.enroll();
        vm.stopPrank();
    }

    // Helpers

    function _prepareUserTwoAndThreeWithShares(address userOne, address userTwo, address userThree, uint256 courseId)
        internal
        returns (uint256)
    {
        // user one sells 15 shares and user two buys
        // user one sells 20 shares and user three buys

        uint256 sharesToSellUserTwo = 15e4;
        uint256 sharesToSellUserThree = 20e4;
        uint256 priceToSellShares = 5e18;

        uint256 listingId = 1;

        _sellShare(courseId, sharesToSellUserTwo, priceToSellShares, userOne);
        _buyShares(listingId, userTwo);

        listingId++;

        _sellShare(courseId, sharesToSellUserThree, priceToSellShares, userOne);
        _buyShares(listingId, userThree);

        return listingId;
    }
}
