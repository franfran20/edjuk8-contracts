// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Types} from "../utils/Types.sol";

interface ISubCourse {
    //  Extrenal Functions

    function enroll() external;

    function uploadNewLesson(string memory name, bool lessonType, string memory gatedLessonURI, uint256 lessonLength)
        external;

    function dropReview(uint8 rating, string memory comment) external;

    // Getter Functions

    function getReviews() external view returns (Types.Review[] memory);

    function getLessons() external view returns (Types.Lesson[] memory);

    function getLessonById(uint256 lessonId) external view returns (Types.Lesson memory);

    function getEnrolledStatus(address user) external view returns (bool);

    function getDetails() external view returns (Types.SubCourse memory);

    function getStatDetails() external view returns (Types.SubCourseStats memory);

    function getCourseHandler() external view returns (address);

    function getEdjuk8Token() external view returns (address);
}
