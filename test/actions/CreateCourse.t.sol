// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {BaseTest} from "../BaseTest.t.sol";
import {Types} from "../../src/utils/Types.sol";
import {Errors} from "../../src/utils/Errors.sol";
import {MetaTx} from "../../src/utils/MetaTx.sol";

import {console} from "forge-std/console.sol";

contract CreateCourseTest is BaseTest {
    function testRegisterUser__UpdatesTheUserDetailsAndUserNameTaken() public {
        address userOne = makeAddr("userOne");
        vm.startPrank(userOne);
        Types.Register memory param = Types.Register({username: usernameOne});
        courseHandler.registerUser(param);
        vm.stopPrank();

        Types.User memory user = courseHandler.getUserDetails(userOne);

        assertEq(user.username, usernameOne);
        assertEq(user.author, true);
    }

    function testCreateCourse__RevertsIfUserIsAlreadyRegistered() public {
        address userOne = makeAddr("userOne");

        Types.CreateCourse memory params = Types.CreateCourse({
            name: courseNameOne,
            description: courseDescriptionOne,
            imageURI: imageURI,
            genre: softwareEng
        });

        vm.startPrank(userOne);
        // not registered
        vm.expectRevert(Errors.Edjuk8__NotRegistered.selector);
        courseHandler.createCourse(params);
        vm.stopPrank();
    }

    function testCreateCourse__RevertsIfTheMxCoursesAllowedIsExceeded() public {
        address userOne = makeAddr("userOne");
        uint256 MAX_ALLOWED_COURSES = 8;

        Types.CreateCourse memory params = Types.CreateCourse({
            name: courseNameOne,
            description: courseDescriptionOne,
            imageURI: imageURI,
            genre: softwareEng
        });

        _registerUser(usernameOne, userOne);

        vm.startPrank(userOne);
        for (uint256 i = 0; i < MAX_ALLOWED_COURSES; i++) {
            courseHandler.createCourse(params);
        }

        vm.expectRevert(Errors.Edjuk8__UserMaxCourseExceeded.selector);
        courseHandler.createCourse(params);

        vm.stopPrank();
    }

    function testCreateCourse__UpdatesTheCourseIdCounterAndPoplatesTheCourseDetails() public {
        address userOne = makeAddr("userOne");
        uint256 courseIdThree = 3;

        Types.CreateCourse memory params = Types.CreateCourse({
            name: courseNameOne,
            description: courseDescriptionOne,
            imageURI: imageURI,
            genre: softwareEng
        });

        _registerUser(usernameOne, userOne);

        vm.startPrank(userOne);
        for (uint256 i = 0; i < 4; i++) {
            courseHandler.createCourse(params);
        }
        vm.stopPrank();

        Types.Course memory courseThree = courseHandler.getCourseById(courseIdThree);

        console.log(courseThree.courseURI);

        assertEq(courseHandler.courseIds(), 4);
        assertEq(courseThree.ID, courseIdThree);
        assertEq(courseThree.ownerName, usernameOne);
        assertEq(courseThree.owner, userOne);
        assertEq(courseThree.shareHolders, 1);
    }

    function testCreateCourse__UpdatesTheCourseAndOwnerShareDetails() public {
        address userOne = makeAddr("userOne");
        uint256 courseIdOne = 1;

        Types.CreateCourse memory params = Types.CreateCourse({
            name: courseNameOne,
            description: courseDescriptionOne,
            imageURI: imageURI,
            genre: softwareEng
        });

        _registerUser(usernameOne, userOne);

        vm.startPrank(userOne);
        // create two courses
        courseHandler.createCourse(params);
        courseHandler.createCourse(params);
        vm.stopPrank();

        (bool isShareHolder, uint256 shareAmount,,) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);
        Types.Course[] memory userCourses = courseHandler.getUserOwnedCourses(userOne);

        assertEq(isShareHolder, true);
        assertEq(shareAmount, courseHandler.CREATION_SHARE());
        assertEq(userCourses.length, 2);
    }

    /////////////////////////////////////////////////////////////////////
    ///////////////////////// With Sig Test /////////////////////////////
    /////////////////////////////////////////////////////////////////////

    function testCreateCourseWithSig__UpdatesTheCourseIdCounterAndPoplatesTheCourseDetails() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");
        uint256 courseIdThree = 3;

        _registerUser(usernameOne, userOne);

        vm.startPrank(makeAddr("Relayerrrr"));
        for (uint256 i = 0; i < 4; i++) {
            courseHandler.createCourseWithSig(_prepareSigParams(userOne, userOneKey));
        }
        vm.stopPrank();

        Types.Course memory courseThree = courseHandler.getCourseById(courseIdThree);

        assertEq(courseHandler.courseIds(), 4);
        assertEq(courseThree.ID, courseIdThree);
        assertEq(courseThree.ownerName, usernameOne);
        assertEq(courseThree.owner, userOne);
        assertEq(courseThree.shareHolders, 1);
    }

    function testCreateCourseWithSig__UpdatesTheCourseAndOwnerShareDetails() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");
        uint256 courseIdOne = 1;

        _registerUser(usernameOne, userOne);

        vm.startPrank(makeAddr("The Relayerr"));
        // create two courses
        courseHandler.createCourseWithSig(_prepareSigParams(userOne, userOneKey));
        courseHandler.createCourseWithSig(_prepareSigParams(userOne, userOneKey));
        vm.stopPrank();

        (bool isShareHolder, uint256 shareAmount,,) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);
        Types.Course[] memory userCourses = courseHandler.getUserOwnedCourses(userOne);

        assertEq(isShareHolder, true);
        assertEq(shareAmount, courseHandler.CREATION_SHARE());
        assertEq(userCourses.length, 2);
    }

    function _prepareSigParams(address user, uint256 userPrivKey)
        private
        view
        returns (Types.CreateCourseWithSig memory)
    {
        //// Signature Setup
        uint256 deadline = block.timestamp + oneMinute;
        uint256 userNonce = courseHandler.getUserDetails(user).nonce + 1;

        Types.CreateCourseWithSig memory params = Types.CreateCourseWithSig({
            user: user,
            name: courseNameOne,
            description: courseDescriptionOne,
            imageURI: imageURI,
            genre: softwareEng,
            deadline: deadline,
            v: 0,
            r: 0x00,
            s: 0x00
        });

        bytes32 structHash = MetaTx._createCourseStructHash(params, userNonce);
        bytes32 digest = courseHandler.getTypedDataHash(structHash);
        (params.v, params.r, params.s) = vm.sign(userPrivKey, digest);
        //////
        return params;
    }
}
