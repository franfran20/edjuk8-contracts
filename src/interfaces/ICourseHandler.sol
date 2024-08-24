// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Types} from "../utils/Types.sol";

interface ICourseHandler {
    struct Course {
        string name;
        string description;
        string imageURI;
        string courseURI;
        string ownerName;
        address owner;
        uint256 studentsEnrolled;
        uint256 ID;
        uint256 courseEarnings;
        uint256 shareEarnings;
        uint256 shareHolders;
        uint8 genre; // 1-> software development, 2-> Business & Finance, 3-> Art & Creativity, 4-> Personal Development
    }

    struct CourseView {
        string name;
        string owner;
        uint256 ID;
        uint256 shareEarnings;
        uint256 ownerEarnings;
    }

    struct User {
        string username;
        Course[] ownedCourses;
        bool author;
        uint256 nonce;
    }

    struct SubCourseDetail {
        address subCourseAddress;
        string name;
        string description;
        string imageURI;
        uint256 createdAt;
        uint256 subCourseId;
    }

    // External Functions

    function registerUser(Types.Register memory params) external;

    function registerUserWithSig(Types.RegisterWithSig memory params) external;

    function createCourse(Types.CreateCourse memory params) external;

    function createCourseWithSig(Types.CreateCourseWithSig memory params) external;

    // // calls the market place contract
    function sellCourseShare(Types.SellShare memory params) external;

    function sellCourseShareWithSig(Types.SellShareWIthSig memory params) external;

    // // gives share back to thhe owner and claim rewards
    function cashInCourseShares(Types.CashInCourseShare memory params) external;

    // // gives share back to thhe owner and claim rewards
    function cashInCourseSharesWithSig(Types.CashInCourseShareWithSig memory params) external;

    // deploy subcourse for users
    // function deploySubCourse(Types.DeploySubCourse memory params) external;

    // deploy subcourse for users
    // function deploySubCourseWithSig(Types.DeploySubCourseWithSig memory params) external;

    function shareUpdate(address seller, address buyer, uint256 courseId, uint256 sharesAmount) external;

    function updateSubCourseEnrollment(uint256 courseId, uint256 enrollmentPrice) external;

    // // Getter Functions

    function getAllCourses() external view returns (Types.Course[] memory);

    // // // get coursse by Id
    function getCourseById(uint256 courseId) external view returns (Types.Course memory);

    function getUserOwnedCourses(address _owner) external view returns (Types.Course[] memory);

    // returns: is share holder, share amount, share amount locked, active listing id
    function getUserCourseShareDetails(uint256 courseId, address user)
        external
        view
        returns (bool, uint256, uint256, uint256);

    function getCourseIdCounter() external view returns (uint256);

    // Events

    // Note User cannnot buy his own shares
    // Errors
}

// // get all sub coursess
// function getSubCourses(uint256 courseId) external view returns (SubCourse[] memory);

// // get all users learnings
// function getMyLearnings(address user) external view returns (SubCourse[] memory);
