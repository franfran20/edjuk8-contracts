// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {BaseTest} from "../BaseTest.t.sol";
import {Types} from "../../src/utils/Types.sol";
import {Errors} from "../../src/utils/Errors.sol";
import {MetaTx} from "../../src/utils/MetaTx.sol";

import {ISubCourse} from "../../src/interfaces/ISubCourse.sol";

import {console} from "forge-std/console.sol";

contract SubCourseDeployerTest is BaseTest {
    uint256 MAX_ALLOWED_SUB_COURSE = 8;
    uint256 MAX_PRICE = 100e18; // 100 edjuk8 tokens

    function testCreateSubCourse__RevertsIfTheUserIsNotTheCourseOwner() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        Types.DeploySubCourse memory params = Types.DeploySubCourse({
            name: subCourseName,
            description: subCourseDescripton,
            imageURI: imageURI,
            price: subCoursePrice,
            focusAreas: focusArea,
            courseId: courseIdOne
        });

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__NotCourseOwner.selector);
        subCourseDeployer.deploySubCourse(params);
        vm.stopPrank();
    }

    function testCreateSubCourse__RevertsIfMaxAllowedSubCourseIsExceeded() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        Types.DeploySubCourse memory params = Types.DeploySubCourse({
            name: subCourseName,
            description: subCourseDescripton,
            imageURI: imageURI,
            price: subCoursePrice,
            focusAreas: focusArea,
            courseId: courseIdOne
        });

        vm.startPrank(userOne);
        for (uint256 i = 0; i < MAX_ALLOWED_SUB_COURSE; i++) {
            subCourseDeployer.deploySubCourse(params);
        }
        vm.expectRevert(Errors.Edjuk8__MaxAllowedSubCoursesExceeded.selector);
        subCourseDeployer.deploySubCourse(params);
        vm.stopPrank();
    }

    function testCreateSubCourse__RevertsIfPriceIsHigherThanMaxPriceAllowed() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        Types.DeploySubCourse memory params = Types.DeploySubCourse({
            name: subCourseName,
            description: subCourseDescripton,
            imageURI: imageURI,
            price: subCoursePrice,
            focusAreas: focusArea,
            courseId: courseIdOne
        });

        vm.startPrank(userOne);
        params.price = MAX_PRICE + 1e18;
        vm.expectRevert(Errors.Edjuk8__MaxSubCoursePriceExceeded.selector);
        subCourseDeployer.deploySubCourse(params);
        vm.stopPrank();
    }

    function testCreateSubCourse__DeploysSubCourseContract() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCourseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        Types.DeploySubCourse memory params = Types.DeploySubCourse({
            name: subCourseName,
            description: subCourseDescripton,
            imageURI: imageURI,
            price: subCoursePrice,
            focusAreas: focusArea,
            courseId: courseIdOne
        });

        vm.startPrank(userOne);
        subCourseDeployer.deploySubCourse(params);
        vm.stopPrank();

        Types.SubCourseDetail memory subCourseOne = subCourseDeployer.getSpecificSubCourse(courseIdOne, subCourseIdOne);
        ISubCourse newlyCreatedSubCourse = ISubCourse(subCourseOne.subCourseAddress);

        assertEq(newlyCreatedSubCourse.getEdjuk8Token(), address(edjuk8Token));
        assertEq(newlyCreatedSubCourse.getCourseHandler(), address(courseHandler));
        assertEq(newlyCreatedSubCourse.getDetails().owner, userOne);
        assertEq(newlyCreatedSubCourse.getDetails().price, subCoursePrice);
    }

    function testCreateSubCourse__UpdatesTheSubCoursesDetailsInTheSubCourseDeployer() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        Types.DeploySubCourse memory params = Types.DeploySubCourse({
            name: subCourseName,
            description: subCourseDescripton,
            imageURI: imageURI,
            price: subCoursePrice,
            focusAreas: focusArea,
            courseId: courseIdOne
        });

        vm.startPrank(userOne);
        uint256 FourSubCourses = 4;
        for (uint256 i = 0; i < FourSubCourses; i++) {
            subCourseDeployer.deploySubCourse(params);
        }
        vm.stopPrank();

        uint256 subCourseIdThree = 3;

        Types.SubCourseDetail[] memory allSubCourses = subCourseDeployer.getSubCourses(courseIdOne);
        Types.SubCourseDetail memory subCourseThree =
            subCourseDeployer.getSpecificSubCourse(courseIdOne, subCourseIdThree);

        assertEq(allSubCourses.length, FourSubCourses);
        assertEq(subCourseThree.subCourseId, subCourseIdThree);
        assertNotEq(subCourseThree.subCourseAddress, address(0));
    }

    /////////////////////////////////////////////////////////////////////
    ///////////////////////// With Sig Test /////////////////////////////
    /////////////////////////////////////////////////////////////////////

    function testCreateSubCourseWithSig__DeploysSubCourseContract() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCourseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        vm.startPrank(makeAddr("Relayer"));
        subCourseDeployer.deploySubCourseWithSig(_prepareSigParams(userOne, userOneKey, subCoursePrice, courseIdOne));
        vm.stopPrank();

        Types.SubCourseDetail memory subCourseOne = subCourseDeployer.getSpecificSubCourse(courseIdOne, subCourseIdOne);
        ISubCourse newlyCreatedSubCourse = ISubCourse(subCourseOne.subCourseAddress);

        assertEq(newlyCreatedSubCourse.getEdjuk8Token(), address(edjuk8Token));
        assertEq(newlyCreatedSubCourse.getCourseHandler(), address(courseHandler));
        assertEq(newlyCreatedSubCourse.getDetails().owner, userOne);
        assertEq(newlyCreatedSubCourse.getDetails().price, subCoursePrice);
    }

    function testCreateSubCourseWithSig__UpdatesTheSubCoursesDetailsInTheSubCourseDeployer() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);
        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        vm.startPrank(makeAddr("Relayer"));
        uint256 FourSubCourses = 4;
        for (uint256 i = 0; i < FourSubCourses; i++) {
            subCourseDeployer.deploySubCourseWithSig(
                _prepareSigParams(userOne, userOneKey, subCoursePrice, courseIdOne)
            );
        }
        vm.stopPrank();

        uint256 subCourseIdThree = 3;

        Types.SubCourseDetail[] memory allSubCourses = subCourseDeployer.getSubCourses(courseIdOne);
        Types.SubCourseDetail memory subCourseThree =
            subCourseDeployer.getSpecificSubCourse(courseIdOne, subCourseIdThree);

        assertEq(allSubCourses.length, FourSubCourses);
        assertEq(subCourseThree.subCourseId, subCourseIdThree);
        assertNotEq(subCourseThree.subCourseAddress, address(0));
    }

    function _prepareSigParams(address user, uint256 userPrivKey, uint256 subCoursePrice, uint256 courseId)
        private
        view
        returns (Types.DeploySubCourseWithSig memory)
    {
        //// Signature Setup
        uint256 deadline = block.timestamp + oneMinute;
        uint256 userNonce = subCourseDeployer.getUserNonce(user) + 1;

        Types.DeploySubCourseWithSig memory params = Types.DeploySubCourseWithSig({
            user: user,
            name: subCourseName,
            description: subCourseDescripton,
            imageURI: imageURI,
            price: subCoursePrice,
            focusAreas: focusArea,
            courseId: courseId,
            deadline: deadline,
            v: 0,
            r: 0x00,
            s: 0x00
        });

        bytes32 structHash = MetaTx._deploySubCourseStructHash(params, userNonce);
        bytes32 digest = subCourseDeployer.getTypedDataHash(structHash);
        (params.v, params.r, params.s) = vm.sign(userPrivKey, digest);
        //////
        return params;
    }
}
