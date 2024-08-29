// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {BaseTest} from "../BaseTest.t.sol";
import {Types} from "../../src/utils/Types.sol";
import {Errors} from "../../src/utils/Errors.sol";
import {MetaTx} from "../../src/utils/MetaTx.sol";

import {ISubCourse} from "../../src/interfaces/ISubCourse.sol";

import {console} from "forge-std/console.sol";

contract SubCourseActionTest is BaseTest {
    uint256 MAX_LESSONS = 12;

    ////////////////////////////////////////////////////////
    ////////////////   LESSON TESTS  ///////////////////////
    ////////////////////////////////////////////////////////

    function testUploadNewLesson__RevertsIfTheUserIsNotTheCourseOwner() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        // Create subCourse
        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);
        ISubCourse subCourse = ISubCourse(subCourseAddress);

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__NotCourseOwner.selector);
        subCourse.uploadNewLesson(lessonName, true, gatedLessonURI, lessonLength);
        vm.stopPrank();
    }

    function testUploadNewLesson__RevertsIfMaxLessonsHaveBeenExceeded() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        // Create subCourse
        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);
        ISubCourse subCourse = ISubCourse(subCourseAddress);

        vm.startPrank(userOne);
        for (uint256 i = 0; i < MAX_LESSONS; i++) {
            subCourse.uploadNewLesson(lessonName, true, gatedLessonURI, lessonLength);
        }
        vm.expectRevert(Errors.Edjuk8__MaxAmountOfLessonsCreated.selector);
        subCourse.uploadNewLesson(lessonName, true, gatedLessonURI, lessonLength);
        vm.stopPrank();
    }

    function testUploadNewLesson__UpdatesTheLessonDetails() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        // Create subCourse
        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);
        ISubCourse subCourse = ISubCourse(subCourseAddress);

        vm.startPrank(userOne);
        for (uint256 i = 0; i < MAX_LESSONS; i++) {
            subCourse.uploadNewLesson(lessonName, true, gatedLessonURI, lessonLength);
        }
        vm.expectRevert(Errors.Edjuk8__MaxAmountOfLessonsCreated.selector);
        subCourse.uploadNewLesson(lessonName, true, gatedLessonURI, lessonLength);
        vm.stopPrank();

        Types.Lesson memory lessonFive = subCourse.getLessonById(5);

        assertEq(lessonFive.ID, 5);
    }

    ////////////////////////////////////////////////////////
    ////////////////   ENROLL TESTS  ///////////////////////
    ////////////////////////////////////////////////////////

    function testEnrollRevertsOnIsufficientAllownaceAndBalance() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        address student = makeAddr("student");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        // Create subCourse
        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);
        ISubCourse subCourse = ISubCourse(subCourseAddress);

        vm.startPrank(student);
        vm.expectRevert(Errors.Edjuk8__InsufficientTokenAllowance.selector);
        subCourse.enroll();

        _approveEdjuk8Token(address(subCourse), subCoursePrice, student);
        vm.expectRevert(Errors.Edjuk8__InsufficientTokenAllowance.selector);
        subCourse.enroll();
        vm.stopPrank();
    }

    function testEnrollRevertsIfTheStudentIsAlreadyEnrolled() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        address student = makeAddr("student");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        // Create subCourse
        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);
        ISubCourse subCourse = ISubCourse(subCourseAddress);

        // enroll
        _enroll(subCourseAddress, subCoursePrice, student);

        // mint and approve to try again
        _mintEdjuk8Tokens(subCoursePrice, student);
        _approveEdjuk8Token(subCourseAddress, subCoursePrice, student);

        vm.startPrank(student);
        vm.expectRevert(Errors.Edjuk8__UserAlreadyEnrolled.selector);
        subCourse.enroll();
        vm.stopPrank();
    }

    function testEnrollTransfersCourseCostFromUser() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        address student = makeAddr("student");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        // Create subCourse
        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);
        ISubCourse subCourse = ISubCourse(subCourseAddress);

        // mint and approve to try again
        _mintEdjuk8Tokens(subCoursePrice, student);
        _approveEdjuk8Token(subCourseAddress, subCoursePrice, student);

        uint256 courseHandlerBalanceBefore = edjuk8Token.balanceOf(address(courseHandler));

        assertEq(subCourse.getEnrolledStatus(student), false);

        vm.startPrank(student);
        subCourse.enroll();
        vm.stopPrank();

        Types.SubCourseStats memory stats = subCourse.getStatDetails();
        uint256 courseHandlerBalanceAfter = edjuk8Token.balanceOf(address(courseHandler));

        assertEq(courseHandlerBalanceAfter, courseHandlerBalanceBefore + subCoursePrice);
        assertEq(subCourse.getEnrolledStatus(student), true);
        assertEq(stats.studentsEnrolled, 1);
        assertEq(stats.earned, subCoursePrice);
    }

    function testEnrollUpdatesSubCourseEnrollmentInCourseHandler() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        address student = makeAddr("student");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user 1 -> 65 shares ,user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        // Create subCourse
        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);
        ISubCourse subCourse = ISubCourse(subCourseAddress);

        // mint and approve to try again
        _mintEdjuk8Tokens(subCoursePrice, student);
        _approveEdjuk8Token(subCourseAddress, subCoursePrice, student);

        // expect revert from caller that is not subcourse
        vm.startPrank(address(shareMarketPlace));
        vm.expectRevert(Errors.Edjuk8__CallerIsNotSubCourse.selector);
        courseHandler.updateSubCourseEnrollment(courseIdOne, subCoursePrice, address(shareMarketPlace));
        vm.stopPrank();

        vm.startPrank(student);
        subCourse.enroll();
        vm.stopPrank();

        Types.Course memory courseOne = courseHandler.getCourseById(courseIdOne);

        assertEq(courseOne.shareEarnings, (subCoursePrice * 35) / 100);
        assertEq(courseOne.courseEarnings, (subCoursePrice * 65) / 100);
        assertEq(courseOne.studentsEnrolled, 1);
    }
}
