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

    /////////////////////////////////////////////////////////////////////
    ///////////////////////// With Sig Test /////////////////////////////
    /////////////////////////////////////////////////////////////////////

    function testCashInShareWithSig__TransfersTheOwnerTheirFundsBasedOnShareBalance() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");
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

        vm.startPrank(makeAddr("Relayerrr"));
        courseHandler.cashInCourseSharesWithSig(_prepareSigParams(userOne, userOneKey, sharesToCashIn, courseIdOne));
        vm.stopPrank();

        uint256 ownerBalAfterCashIn = edjuk8Token.balanceOf(userOne);
        Types.Course memory courseOne = courseHandler.getCourseById(courseIdOne);
        (bool isShareHolder, uint256 userCourseShares,,) = courseHandler.getUserCourseShareDetails(courseIdOne, userOne);

        assertEq(ownerBalAfterCashIn, ownerBalBeforeCashIn + ((subCoursePrice * 65) / 100) * 3);
        assertEq(courseOne.courseEarnings, 0);
        assertEq(isShareHolder, true);
        assertEq(userCourseShares, 65e4);
    }

    function testCashInShareWithSig__UpdatesShareDetailsAccordingly() public {
        address userOne = makeAddr("userOne");
        (address userTwo, uint256 userTwoKey) = makeAddrAndKey("userTwo");
        address userThree = makeAddr("userThree");

        uint256 courseIdOne = 1;
        uint256 sharesToCashIn = 10e4;
        uint256 subCoursePrice = 20e18;

        _registerUser(usernameOne, userOne);
        _createCourse(userOne);

        // user2 -> 15 shares, user 3 -> 20 shares, user 1 -> 65 shares
        _prepareUserTwoAndThreeWithShares(userOne, userTwo, userThree, courseIdOne);

        (, address subCourseAddress) = _createSubCourse(courseIdOne, subCoursePrice, userOne);

        _enroll(subCourseAddress, subCoursePrice, makeAddr("stud1"));
        _enroll(subCourseAddress, subCoursePrice, makeAddr("stud2"));
        _enroll(subCourseAddress, subCoursePrice, makeAddr("stud3"));

        _sellShare(courseIdOne, 5e4, 3 ether, userTwo);

        uint256 latestListing = shareMarketPlace.shareListings();
        uint256 userBalanceBeforeCashIn = edjuk8Token.balanceOf(userTwo);

        vm.startPrank(makeAddr("Relayerrr"));
        courseHandler.cashInCourseSharesWithSig(_prepareSigParams(userTwo, userTwoKey, sharesToCashIn, courseIdOne));
        vm.stopPrank();

        uint256 userBalanceAfterCashIn = edjuk8Token.balanceOf(userTwo);
        (bool isShareHolder, uint256 userCourseShares,,) = courseHandler.getUserCourseShareDetails(courseIdOne, userTwo);
        bool listingValidity = shareMarketPlace.getShareListingById(latestListing).valid;

        assertEq(listingValidity, true);
        assertEq(userBalanceAfterCashIn, userBalanceBeforeCashIn + ((sharesToCashIn * 7e18) / 35e4) * 3);
        assertEq(isShareHolder, false);
        assertEq(userCourseShares, 0);
    }

    // ////////////////////// //////////////////////
    //////////// Private Functions /////////////////
    ////////////////////////////////////////////////

    function _prepareSigParams(address user, uint256 userPrivKey, uint256 sharesToCashIn, uint256 courseId)
        private
        view
        returns (Types.CashInCourseShareWithSig memory)
    {
        //// Signature Setup
        uint256 deadline = block.timestamp + oneMinute;
        uint256 userNonce = courseHandler.getUserDetails(user).nonce + 1;

        Types.CashInCourseShareWithSig memory params = Types.CashInCourseShareWithSig({
            user: user,
            courseId: courseId,
            sharesAmount: sharesToCashIn,
            deadline: deadline,
            v: 0,
            r: 0x00,
            s: 0x00
        });

        bytes32 structHash = MetaTx._cashInCourseShareStructHash(params, userNonce);
        bytes32 digest = courseHandler.getTypedDataHash(structHash);
        (params.v, params.r, params.s) = vm.sign(userPrivKey, digest);
        //////
        return params;
    }
}
