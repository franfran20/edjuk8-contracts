// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {BaseTest} from "../BaseTest.t.sol";
import {Types} from "../../src/utils/Types.sol";
import {Errors} from "../../src/utils/Errors.sol";
import {MetaTx} from "../../src/utils/MetaTx.sol";

import {ISubCourse} from "../../src/interfaces/ISubCourse.sol";

import {console} from "forge-std/console.sol";

contract CashInSharesTest is BaseTest {
    function testCashInShare__RevertsWhen__TheUserIsNotShareHolder() public {
        address userOne = makeAddr("userOne");
        address nonShareHolder = makeAddr("nonShareHolder");

        uint256 courseIdOne = 1;
        uint256 sharesToCashIn = 5e4;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        Types.CashInCourseShare memory params =
            Types.CashInCourseShare({courseId: courseIdOne, sharesAmount: sharesToCashIn});

        vm.startPrank(nonShareHolder);
        vm.expectRevert(Errors.Edjuk8__UserIsNotAShareHolder.selector);
        courseHandler.cashInCourseShares(params);
        vm.stopPrank();
    }

    function testCashInShare__RevertsWhen__UserIsShareHolderButHasZeroShares() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToCashIn = 15e4;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15 shares, user 3 -> 20 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        Types.CashInCourseShare memory params =
            Types.CashInCourseShare({courseId: courseIdOne, sharesAmount: sharesToCashIn});

        // put all shares up for sale
        _sellShare(courseIdOne, sharesToCashIn, 1e18, userTwo);

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__UserHasZeroShares.selector);
        courseHandler.cashInCourseShares(params);
        vm.stopPrank();
    }

    function testCashInShare__RevertsWhen__UserShareBalanceIsInsufficient() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 shareGreaterThanBal = 30e4;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15 shares, user 3 -> 20 shares, user 1 -> 65 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        Types.CashInCourseShare memory params =
            Types.CashInCourseShare({courseId: courseIdOne, sharesAmount: shareGreaterThanBal});

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__InsufficentSharesBalance.selector);
        courseHandler.cashInCourseShares(params);
        vm.stopPrank();
    }

    function testCashInShare__RevertsWhen__CourseOwnerShareOrShareHolderBalanceIsEmpty() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToCashIn = 65e4;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15 shares, user 3 -> 20 shares, user 1 -> 65 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        Types.CashInCourseShare memory params =
            Types.CashInCourseShare({courseId: courseIdOne, sharesAmount: sharesToCashIn});

        vm.startPrank(userOne);
        vm.expectRevert("No balance");
        courseHandler.cashInCourseShares(params);
        vm.stopPrank();

        vm.startPrank(userTwo);
        params.sharesAmount = 10e4;
        vm.expectRevert("No balance");
        courseHandler.cashInCourseShares(params);
        vm.stopPrank();
    }

    function testCashInShare__TransfersTheOwnerTheirFundsBasedOnShareBalance() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToCashIn = 65e4;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15 shares, user 3 -> 20 shares, user 1 -> 65 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);
        // ISubCourse subCourse = ISubCourse(subCourseAddress);

        _enroll(subCourseAddress, subCoursePrice, makeAddr("stud1"));
        _enroll(subCourseAddress, subCoursePrice, makeAddr("stud2"));
        _enroll(subCourseAddress, subCoursePrice, makeAddr("stud3"));

        uint256 ownerBalBeforeCashIn = edjuk8Token.balanceOf(userOne);

        Types.CashInCourseShare memory params =
            Types.CashInCourseShare({courseId: courseIdOne, sharesAmount: sharesToCashIn});

        vm.startPrank(userOne);
        courseHandler.cashInCourseShares(params);
        vm.stopPrank();

        uint256 ownerBalAfterCashIn = edjuk8Token.balanceOf(userOne);
        Types.Course memory courseOne = courseHandler.getCourseById(courseIdOne);
        (bool isShareHolder, uint256 userCourseShares,,) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);

        assertEq(ownerBalAfterCashIn, ownerBalBeforeCashIn + ((subCoursePrice * 65) / 100) * 3);
        assertEq(courseOne.courseEarnings, 0);
        assertEq(isShareHolder, true);
        assertEq(userCourseShares, 65e4);
    }

    function testCashInShare__UpdatesShareDetailsAccordingly() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToCashIn = 10e4;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15 shares, user 3 -> 20 shares, user 1 -> 65 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);
        // ISubCourse subCourse = ISubCourse(subCourseAddress);

        _enroll(subCourseAddress, subCoursePrice, makeAddr("stud1"));
        _enroll(subCourseAddress, subCoursePrice, makeAddr("stud2"));
        _enroll(subCourseAddress, subCoursePrice, makeAddr("stud3"));

        _sellShare(courseIdOne, 5e4, 3 ether, userTwo);
        uint256 latestListing = shareMarketPlace.shareListings();

        uint256 userBalanceBeforeCashIn = edjuk8Token.balanceOf(userTwo);

        Types.CashInCourseShare memory params =
            Types.CashInCourseShare({courseId: courseIdOne, sharesAmount: sharesToCashIn});

        vm.startPrank(userTwo);
        courseHandler.cashInCourseShares(params);
        vm.stopPrank();

        uint256 userBalanceAfterCashIn = edjuk8Token.balanceOf(userTwo);
        (bool isShareHolder, uint256 userCourseShares,,) = courseHandler.getUserCourseShareDetails(courseIdOne, userTwo);
        bool listingValidity = shareMarketPlace.getShareListingById(latestListing).valid;

        assertEq(listingValidity, true);
        assertEq(userBalanceAfterCashIn, userBalanceBeforeCashIn + ((sharesToCashIn * 7e18) / 35e4) * 3);
        assertEq(isShareHolder, false);
        assertEq(userCourseShares, 0);
    }

    // WE STOPPPED HERREEE
    //  BECAUSE WE NEED SUB COURSES TO EARN US SOME FUNDS

    // Look out
    // userCourseShares
    // isShareHolder
    // user ownedCourses

    //     uint256 courseIndex = courseId - 1;
    //     Types.Course memory course = allCourses[courseIndex];

    //     } else {
    //         // we cancel the user share listing on market place
    //
    //         uint256 cashInAmount = (course.shareEarnings * sharesAmount) / 100e4;

    //         allCourses[courseIndex].courseEarnings -= cashInAmount;
    //         _userCourseShares[user][courseId] -= sharesAmount;

    //         if (_userCourseShares[user][courseId] == 0) {
    //             _isShareHolder[user][courseId] = false;
    //             allCourses[courseIndex].shareHolders -= 1;
    //             _removeCourseFromOwnedCourses(user, courseId);
    //         }

    //         (bool success) = edjuk8Token.transfer(user, cashInAmount);
    //         if (!success) {
    //             revert Errors.Edjuk8__TokenTransferFailed();
    //         }
    //     }
    // }

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
