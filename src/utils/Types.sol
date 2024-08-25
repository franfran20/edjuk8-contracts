// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

library Types {
    // CUSTOM TYPES

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

    struct SubCourse {
        string name;
        string description;
        string imageURI;
        uint256 courseId;
        uint256 subCourseId;
        address owner;
        uint256 price;
        string focusAreas;
    }

    struct SubCourseStats {
        uint256 studentsEnrolled;
        uint256 earned;
    }

    struct Lesson {
        string name;
        bool lessonType; // lessonType : true -> video && false -> article
        string gatedLessonURI;
        uint256 lessonLength;
        uint256 ID;
    }

    struct Review {
        uint8 rating;
        string comment;
        address user;
    }

    // FUNCTION PARAMS

    struct Register {
        string username;
    }

    struct RegisterWithSig {
        address user;
        string username;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct CreateCourse {
        string name;
        string description;
        string imageURI;
        uint8 genre;
    }

    struct CreateCourseWithSig {
        address user;
        string name;
        string description;
        string imageURI;
        uint8 genre;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct SellShare {
        uint256 courseId;
        uint256 sharesAmount;
        uint256 price;
    }

    struct SellShareWithSig {
        address user;
        uint256 courseId;
        uint256 sharesAmount;
        uint256 price;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ShareListing {
        address seller;
        uint256 courseId;
        uint256 shareAmount;
        uint256 totalPrice;
        string courseName;
        string courseOwner;
        string imageURI;
        bool valid;
        address purchased;
        uint256 ID;
    }

    struct TransferShare {
        uint256 courseId;
        uint256 sharesAmount;
        address to;
    }

    struct TransferShareWithSig {
        address user;
        uint256 courseId;
        uint256 sharesAmount;
        address to;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct CashInCourseShare {
        uint256 courseId;
        uint256 sharesAmount;
    }

    struct CashInCourseShareWithSig {
        address user;
        uint256 courseId;
        uint256 sharesAmount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct DeploySubCourse {
        string name;
        string description;
        string imageURI;
        uint256 price;
        string focusAreas;
        uint256 courseId;
    }

    struct DeploySubCourseWithSig {
        address user;
        string name;
        string description;
        string imageURI;
        uint256 price;
        string focusAreas;
        uint256 courseId;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
