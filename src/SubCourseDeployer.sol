// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Types} from "./utils/Types.sol";
import {ICourseHandler} from "./interfaces/ICourseHandler.sol";
import {MetaTx} from "./utils/MetaTx.sol";
import {Errors} from "./utils/Errors.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SubCourse} from "./SubCourse.sol";

contract SubCourseDeployer is EIP712, ReentrancyGuard {
    ICourseHandler courseHandler;
    IERC20 edjuk8Token;

    uint256 MAX_ALLOWED_SUB_COURSE = 8;
    uint256 MAX_PRICE = 100e18;

    address dev;

    mapping(address user => uint256 nonce) _nonces;
    mapping(uint256 courseId => uint256 subCourseId) _subCourseIdCounter;
    mapping(uint256 courseId => Types.SubCourseDetail[]) _subCourses;

    modifier courseMustExist(uint256 courseId) {
        require(courseId <= courseHandler.getCourseIdCounter(), "Non Existent Course");
        _;
    }

    constructor(address courseHandlerAddress, address edjuk8TokenAddress) EIP712("SubCourse Deployer", "1") {
        courseHandler = ICourseHandler(courseHandlerAddress);
        dev = msg.sender;
        edjuk8Token = IERC20(edjuk8TokenAddress);
    }

    // External Function

    function deploySubCourse(Types.DeploySubCourse memory params)
        external
        courseMustExist(params.courseId)
        nonReentrant
        returns (uint256 subCourseId, address subCourseAddress)
    {
        (subCourseId, subCourseAddress) = _deploySubCourse(
            params.name,
            params.description,
            params.imageURI,
            params.price,
            params.focusAreas,
            params.courseId,
            msg.sender
        );
    }

    function deploySubCourseWithSig(Types.DeploySubCourseWithSig memory params)
        external
        courseMustExist(params.courseId)
        nonReentrant
        returns (uint256 subCourseId, address subCourseAddress)
    {
        _nonces[params.user]++;

        bytes32 structHash = MetaTx._deploySubCourseStructHash(params, _nonces[params.user]);
        address signer = ECDSA.recover(_hashTypedDataV4(structHash), params.v, params.r, params.s);
        if (signer != params.user) {
            revert Errors.Edjuk8__InvalidSigner();
        }

        (subCourseId, subCourseAddress) = _deploySubCourse(
            params.name,
            params.description,
            params.imageURI,
            params.price,
            params.focusAreas,
            params.courseId,
            params.user
        );
    }

    //  Internal/Private Functions

    function _deploySubCourse(
        string memory name,
        string memory description,
        string memory imageURI,
        uint256 price,
        string memory focusAreas,
        uint256 courseId,
        address user
    ) private returns (uint256, address) {
        Types.Course memory course = courseHandler.getCourseById(courseId);

        if (user != course.owner) revert Errors.Edjuk8__NotCourseOwner();
        if (_subCourses[courseId].length >= MAX_ALLOWED_SUB_COURSE) {
            revert Errors.Edjuk8__MaxAllowedSubCoursesExceeded();
        }
        if (price > MAX_PRICE) revert Errors.Edjuk8__MaxSubCoursePriceExceeded();

        _subCourseIdCounter[courseId]++;

        uint256 subCourseId = _subCourseIdCounter[courseId];

        address subCourseAddress =
            _deployAndSaveSubCourse(user, name, description, imageURI, courseId, subCourseId, price, focusAreas);

        return (subCourseId, subCourseAddress);
    }

    function _deployAndSaveSubCourse(
        address user,
        string memory name,
        string memory description,
        string memory imageURI,
        uint256 courseId,
        uint256 subCourseId,
        uint256 price,
        string memory focusAreas
    ) internal returns (address) {
        SubCourse deployedSubCourse = new SubCourse(
            name,
            description,
            imageURI,
            courseId,
            subCourseId,
            price,
            user,
            focusAreas,
            address(courseHandler),
            address(edjuk8Token)
        );

        _subCourses[courseId].push(
            Types.SubCourseDetail({
                subCourseAddress: address(deployedSubCourse),
                name: name,
                description: description,
                imageURI: imageURI,
                createdAt: block.timestamp,
                subCourseId: subCourseId
            })
        );

        return address(deployedSubCourse);
    }

    // Getter Functions

    function getSubCourses(uint256 courseId) external view returns (Types.SubCourseDetail[] memory) {
        if (courseId > 0) {
            return _subCourses[courseId];
        } else {
            revert Errors.Edjuk8__InvalidCourseId();
        }
    }

    function getSpecificSubCourse(uint256 courseId, uint256 subCourseId)
        external
        view
        returns (Types.SubCourseDetail memory)
    {
        if (courseId > 0) {
            uint256 subCourseIndex = subCourseId - 1;
            return _subCourses[courseId][subCourseIndex];
        } else {
            revert Errors.Edjuk8__InvalidCourseId();
        }
    }

    function getUserNonce(address user) public view returns (uint256) {
        return _nonces[user];
    }

    function getTypedDataHash(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }
}
