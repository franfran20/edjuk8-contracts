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

    function sellCourseShare(Types.SellShare memory params) external;

    function sellCourseShareWithSig(Types.SellShareWithSig memory params) external;

    function cashInCourseShares(Types.CashInCourseShare memory params) external;

    function cashInCourseSharesWithSig(Types.CashInCourseShareWithSig memory params) external;

    function shareUpdate(address seller, address buyer, uint256 courseId, uint256 sharesAmount) external;

    function updateSubCourseEnrollment(uint256 courseId, uint256 enrollmentPrice, address user) external;

    // Getter Functions

    function getAllCourses() external view returns (Types.Course[] memory);

    function getCourseById(uint256 courseId) external view returns (Types.Course memory);

    function getUserOwnedCourses(address _owner) external view returns (Types.Course[] memory);

    // returns: isShareHolder, userShareAmount, userSharesLocked, userActiveListingId
    function getUserCourseShareDetails(uint256 courseId, address user)
        external
        view
        returns (bool, uint256, uint256, uint256);

    function getCourseIdCounter() external view returns (uint256);
}
