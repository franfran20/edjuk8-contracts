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

    // struct RegisterWithSig {
    //     address user;
    //     string username;
    //     uint256 deadline;
    //     uint8 v;
    //     bytes32 r;
    //     bytes32 s;
    // }

    // function testRegisterUserWithSig__UpdatesTheUserDetailsAndUserNameTaken() public {
    //     (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");
    //     // address userTwo = makeAddr("userTwo");

    //     uint256 deadline = block.timestamp + oneMinute;
    //     uint256 userNonce = courseHandler.getUserDetails(userOne).nonce + 1;

    //     vm.startPrank(userOne);

    //     Types.RegisterWithSig memory params =
    //         Types.RegisterWithSig({user: userOne, username: usernameOne, deadline: deadline, v: 0, r: 0x00, s: 0x00});

    //     bytes32 structHash = MetaTx._registerStructHash(params, userNonce);
    //     bytes32 digest = courseHandler.getTypedDataHash(structHash);

    //     (params.v, params.r, params.s) = vm.sign(userOneKey, digest);

    //     courseHandler.registerUserWithSig(params);
    //     vm.stopPrank();

    //     Types.User memory user = courseHandler.getUserDetails(userOne);
    //     assertEq(user.username, usernameOne);
    //     assertEq(user.author, true);
    // }

    function _prepareUserTwoAndThreeWithShares(address userOne, address userTwo, address userThree, uint256 courseId)
        private
        returns (uint256)
    {
        // user one sells 15 shares and user two buys
        // user one sells 20 shares and user three buys

        uint256 sharesToSellUserTwo = 15e4;
        uint256 sharesToSellUserThree = 20e4;
        uint256 priceToSellShares = 5e18;

        uint256 listingId = 1;

        _sellShare(courseId, sharesToSellUserTwo, priceToSellShares, userOne);
        _buyShares(listingId, userTwo);

        listingId++;

        _sellShare(courseId, sharesToSellUserThree, priceToSellShares, userOne);
        _buyShares(listingId, userThree);

        return listingId;
    }
}
