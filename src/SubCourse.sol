// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ISubCourse} from "./interfaces/ISubCourse.sol";
import {ICourseHandler} from "./interfaces/ICourseHandler.sol";
import {Types} from "./utils/Types.sol";
import {Errors} from "./utils/Errors.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SubCourse is ISubCourse {
    uint256 public constant MAX_LESSONS = 12;

    Types.SubCourse subCourse;
    Types.SubCourseStats subCourseStats;

    IERC20 edjuk8Token;
    ICourseHandler courseHandler;

    uint256 lessonIdCounter;

    Types.Lesson[] lessons;
    Types.Review[] reviews;

    mapping(address user => bool enrolled) _userEnrolled;
    mapping(address user => bool reviewed) _reviewed;

    // 200 by default on finsihing course
    // The idea for the future is for it to be flexible by admins
    // Where they can have codes like 321 for passing an exam or something and can update it at will per user
    mapping(address user => uint256 amount) _completedTokenStatus;

    constructor(
        string memory name,
        string memory description,
        string memory imageURI,
        uint256 courseId,
        uint256 subCourseId,
        uint256 price,
        address courseOwner,
        string memory focusAreas,
        address courseHandlerAddress,
        address edjuk8TokenAddress
    ) {
        subCourse = Types.SubCourse({
            name: name,
            description: description,
            imageURI: imageURI,
            courseId: courseId,
            subCourseId: subCourseId,
            owner: courseOwner,
            price: price,
            focusAreas: focusAreas
        });

        courseHandler = ICourseHandler(courseHandlerAddress);
        edjuk8Token = IERC20(edjuk8TokenAddress);
    }

    function uploadNewLesson(string memory name, bool lessonType, string memory gatedLessonURI, uint256 lessonLength)
        external
    {
        if (msg.sender != subCourse.owner) {
            revert Errors.Edjuk8__NotCourseOwner();
        }
        if (lessons.length >= MAX_LESSONS) {
            revert Errors.Edjuk8__MaxAmountOfLessonsCreated();
        }

        lessonIdCounter += 1;

        lessons.push(
            Types.Lesson({
                name: name,
                lessonType: lessonType,
                gatedLessonURI: gatedLessonURI,
                lessonLength: lessonLength,
                ID: lessonIdCounter
            })
        );
    }

    function enroll() external {
        if (edjuk8Token.allowance(msg.sender, address(this)) < subCourse.price) {
            revert Errors.Edjuk8__InsufficientTokenAllowance();
        }
        if (edjuk8Token.balanceOf(msg.sender) < subCourse.price) {
            revert Errors.Edjuk8__InsuficientTokenBalance();
        }

        if (_userEnrolled[msg.sender]) {
            revert Errors.Edjuk8__UserAlreadyEnrolled();
        }

        _userEnrolled[msg.sender] = true;

        edjuk8Token.transferFrom(msg.sender, address(courseHandler), subCourse.price);

        subCourseStats.studentsEnrolled += 1;
        subCourseStats.earned += subCourse.price;

        courseHandler.updateSubCourseEnrollment(subCourse.courseId, subCourse.price);
    }

    function dropReview(uint8 rating, string memory comment) external {
        if (!_userEnrolled[msg.sender]) {
            revert Errors.Edjuk8__UserNotEnrolled();
        }

        if (_reviewed[msg.sender]) {
            revert Errors.Edjuk8__UserAlreadyReviewed();
        }

        reviews.push(Types.Review({rating: rating, comment: comment, user: msg.sender}));
    }

    function issueCompletedTokenStatus(address user, uint256 status) external {
        if (status != 200) {
            if (msg.sender != subCourse.owner) {
                revert Errors.Edjuk8__NotCourseOwner();
            }
        }
        if (!_userEnrolled[user]) {
            revert Errors.Edjuk8__UserNotEnrolled();
        }

        _completedTokenStatus[user] = status;
    }

    // Getter Functions

    function getDetails() external view returns (Types.SubCourse memory) {
        return subCourse;
    }

    function getStatDetails() external view returns (Types.SubCourseStats memory) {
        return subCourseStats;
    }

    function getReviews() external view returns (Types.Review[] memory) {
        return reviews;
    }

    function getLessons() external view returns (Types.Lesson[] memory) {
        return lessons;
    }

    function getLessonById(uint256 lessonId) external view returns (Types.Lesson memory) {
        if (lessonId > 0) {
            uint256 lessonIndex = lessonId - 1;
            return lessons[lessonIndex];
        } else {
            revert Errors.Edjuk8__InvalidLessonID();
        }
    }

    function getEnrolledStatus(address user) external view returns (bool) {
        return _userEnrolled[user];
    }

    function getCourseHandler() external view returns (address) {
        return address(courseHandler);
    }

    function getEdjuk8Token() external view returns (address) {
        return address(edjuk8Token);
    }
}
