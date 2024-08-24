// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Types} from "../utils/Types.sol";

interface ISubCourse {
    function enroll() external;

    // lessonType : true -> video && false -> article

    // siteLessonURI doesnt reveal the lesson itself rather it sends it to somewhere that has the lesson encrypted
    // e.g the edjuk8 site, your own personal site and then you could implement checks on your own site to make sure the user
    // has enrolled for the course before decrypting the course detail to them

    // lesson Length is basically average time to compleet the lesson
    function uploadNewLesson(string memory name, bool lessonType, string memory gatedLessonURI, uint256 lessonLength)
        external;

    function dropReview(uint8 rating, string memory comment) external;

    // getter functions

    function getReviews() external view returns (Types.Review[] memory);

    function getLessons() external view returns (Types.Lesson[] memory);

    function getLessonById(uint256 lessonId) external view returns (Types.Lesson memory);

    function getEnrolledStatus(address user) external view returns (bool);

    function getDetails() external view returns (Types.SubCourse memory);

    function getStatDetails() external view returns (Types.SubCourseStats memory);

    function getCourseHandler() external view returns (address);

    function getEdjuk8Token() external view returns (address);

    // Errors
}
