// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {BaseTest} from "../BaseTest.t.sol";
import {Types} from "../../src/utils/Types.sol";
import {Errors} from "../../src/utils/Errors.sol";
import {MetaTx} from "../../src/utils/MetaTx.sol";

contract RegisterUserTest is BaseTest {
    //    ( address userOne, uint256 userOneKey) = makeAddr("userOne");
    //     (address userTwo, uint256 userTwoKey) = makeAddr("userThree");
    //    ( address userThree, uint256 userThreeKey) = makeAddr("userThree");

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

    function testRegisterUser__RevertsIfTheUserIsAlreadyRegistered() public {
        address userOne = makeAddr("userOne");
        vm.startPrank(userOne);
        Types.Register memory param = Types.Register({username: usernameOne});
        courseHandler.registerUser(param);

        vm.expectRevert(Errors.Edjuk8__AlreadyRegistered.selector);
        courseHandler.registerUser(param);

        vm.stopPrank();
    }

    function testRegisterUser__RevertsIfTheUsernameExceedsMasxCharacterLength() public {
        address userOne = makeAddr("userOne");
        string memory usernameExceedingMaxCharacterLength = "Maxxxxxxxxxxxxxxxxxxxx";

        vm.startPrank(userOne);
        Types.Register memory param = Types.Register({username: usernameExceedingMaxCharacterLength});

        vm.expectRevert(Errors.Edjuk8__UsernameCharactersExceeded.selector);
        courseHandler.registerUser(param);
        vm.stopPrank();
    }

    function testRegisterUser__RevertsIfTheUsernameHasBeenTaken() public {
        address userOne = makeAddr("userOne");
        address userTwo = makeAddr("userThree");

        vm.startPrank(userOne);
        Types.Register memory param = Types.Register({username: usernameOne});
        courseHandler.registerUser(param);
        vm.stopPrank();

        vm.startPrank(userTwo);
        vm.expectRevert(Errors.Edjuk8__UsernameTaken.selector);
        courseHandler.registerUser(param);
        vm.stopPrank();
    }

    ////////////////////////////////////////////////
    ////////////// With Sig Test ///////////////////
    ////////////////////////////////////////////////

    function testRegisterUserWithSig__UpdatesTheUserDetailsAndUserNameTaken() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");
        // address userTwo = makeAddr("userTwo");

        uint256 deadline = block.timestamp + oneMinute;
        uint256 userNonce = courseHandler.getUserDetails(userOne).nonce + 1;

        vm.startPrank(userOne);

        Types.RegisterWithSig memory params =
            Types.RegisterWithSig({user: userOne, username: usernameOne, deadline: deadline, v: 0, r: 0x00, s: 0x00});

        bytes32 structHash = MetaTx._registerStructHash(params, userNonce);
        bytes32 digest = courseHandler.getTypedDataHash(structHash);

        (params.v, params.r, params.s) = vm.sign(userOneKey, digest);

        courseHandler.registerUserWithSig(params);
        vm.stopPrank();

        Types.User memory user = courseHandler.getUserDetails(userOne);
        assertEq(user.username, usernameOne);
        assertEq(user.author, true);
    }

    function testRegisterUserWithSig__RevertsOnInvalidSigner() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");
        address userTwo = makeAddr("userTwo");

        uint256 deadline = block.timestamp + oneMinute;
        uint256 userNonce = courseHandler.getUserDetails(userOne).nonce + 1;

        vm.startPrank(userOne);

        Types.RegisterWithSig memory params =
            Types.RegisterWithSig({user: userTwo, username: usernameOne, deadline: deadline, v: 0, r: 0x00, s: 0x00});

        bytes32 structHash = MetaTx._registerStructHash(params, userNonce);
        bytes32 digest = courseHandler.getTypedDataHash(structHash);

        (params.v, params.r, params.s) = vm.sign(userOneKey, digest);

        vm.expectRevert(Errors.Edjuk8__InvalidSigner.selector);
        courseHandler.registerUserWithSig(params);

        vm.stopPrank();
    }

    function testRegisterUserWithSig__RevertsOnWrongUsernameParam() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");

        uint256 deadline = block.timestamp + oneMinute;
        uint256 userNonce = courseHandler.getUserDetails(userOne).nonce + 1;

        vm.startPrank(userOne);

        Types.RegisterWithSig memory params =
            Types.RegisterWithSig({user: userOne, username: usernameOne, deadline: deadline, v: 0, r: 0x00, s: 0x00});

        bytes32 structHash = MetaTx._registerStructHash(params, userNonce);
        bytes32 digest = courseHandler.getTypedDataHash(structHash);

        (params.v, params.r, params.s) = vm.sign(userOneKey, digest);
        // diffreent user name than signed
        params.username = "strong johns";

        vm.expectRevert(Errors.Edjuk8__InvalidSigner.selector);
        courseHandler.registerUserWithSig(params);

        vm.stopPrank();
    }

    function testRegisterUserWithSig__RevertsOnWrongDeadlineParam() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");

        uint256 deadline = block.timestamp + oneMinute;
        uint256 userNonce = courseHandler.getUserDetails(userOne).nonce + 1;

        vm.startPrank(userOne);

        Types.RegisterWithSig memory params =
            Types.RegisterWithSig({user: userOne, username: usernameOne, deadline: deadline, v: 0, r: 0x00, s: 0x00});

        bytes32 structHash = MetaTx._registerStructHash(params, userNonce);
        bytes32 digest = courseHandler.getTypedDataHash(structHash);

        (params.v, params.r, params.s) = vm.sign(userOneKey, digest);
        // diffreent deadline than signed
        params.deadline = block.timestamp + oneMinute + 30;

        vm.expectRevert(Errors.Edjuk8__InvalidSigner.selector);
        courseHandler.registerUserWithSig(params);

        vm.stopPrank();
    }

    function testFail_RegisterUserWithSig__RevertsOnInfeasibleDeadline() public {
        (address userOne, uint256 userOneKey) = makeAddrAndKey("userOne");

        uint256 userNonce = courseHandler.getUserDetails(userOne).nonce + 1;

        vm.startPrank(userOne);

        Types.RegisterWithSig memory params = Types.RegisterWithSig({
            user: userOne,
            username: usernameOne,
            deadline: block.timestamp,
            v: 0,
            r: 0x00,
            s: 0x00
        });

        bytes32 structHash = MetaTx._registerStructHash(params, userNonce);
        bytes32 digest = courseHandler.getTypedDataHash(structHash);

        (params.v, params.r, params.s) = vm.sign(userOneKey, digest);

        // vm.expectRevert(Errors.Edjuk8__InvalidSigDeadline.selector);
        courseHandler.registerUserWithSig(params);

        vm.stopPrank();
    }
}
