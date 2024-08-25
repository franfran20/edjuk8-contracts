// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Types} from "./Types.sol";
import {Errors} from "./Errors.sol";

library MetaTx {
    bytes32 constant REGISTER_USER = keccak256("Register(address user,string username,uint256 nonce,uint256 deadline)");

    bytes32 constant CREATE_COURSE = keccak256(
        "CreateCourse(address user,string name,string description,string imageURI,uint8 genre,uint256 nonce,uint256 deadline)"
    );

    bytes32 constant SELL_SHARE = keccak256(
        "SellShare(address user,uint256 courseId,uint256 sharesAmount,uint256 price,uint256 nonce,uint256 deadline)"
    );

    bytes32 constant TRANSFER_SHARE = keccak256(
        "TransferCourseShare(address user,uint256 courseId,uint256 sharesAmount,address to,uint256 nonce,uint256 deadline)"
    );

    bytes32 constant CASH_IN_COURSE_SHARE = keccak256(
        "CashInCourseShares(address user,uint256 courseId,uint256 sharesAmount,uint256 nonce,uint256 deadline)"
    );

    bytes32 constant DEPLOY_SUB_COURSE = keccak256(
        "DeploySubCourse(address user,uint256 courseId,string name,string description,string imageURI,uint256 price,string focusAreas,uint256 nonce,uint256 deadline)"
    );

    function _registerStructHash(Types.RegisterWithSig memory params, uint256 nonce) public view returns (bytes32) {
        if (params.deadline <= block.timestamp) revert Errors.Edjuk8__InvalidSigDeadline();
        bytes32 structHash = keccak256(abi.encode(REGISTER_USER, params.user, params.username, nonce, params.deadline));

        return structHash;
    }

    function _createCourseStructHash(Types.CreateCourseWithSig memory params, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        if (block.timestamp > params.deadline) revert Errors.Edjuk8__InvalidSigDeadline();
        bytes32 structHash = keccak256(
            abi.encode(
                CREATE_COURSE,
                params.user,
                params.name,
                params.description,
                params.imageURI,
                params.genre,
                nonce,
                params.deadline
            )
        );

        return structHash;
    }

    function _sellSharesStructHash(Types.SellShareWithSig memory params, uint256 nonce) public view returns (bytes32) {
        if (block.timestamp > params.deadline) revert Errors.Edjuk8__InvalidSigDeadline();
        bytes32 structHash = keccak256(
            abi.encode(
                SELL_SHARE, params.user, params.courseId, params.sharesAmount, params.price, nonce, params.deadline
            )
        );
        return structHash;
    }

    function _transferShareStructHash(Types.TransferShareWithSig memory params, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        if (block.timestamp > params.deadline) revert Errors.Edjuk8__InvalidSigDeadline();
        bytes32 structHash = keccak256(
            abi.encode(
                TRANSFER_SHARE, params.user, params.courseId, params.sharesAmount, params.to, nonce, params.deadline
            )
        );
        return structHash;
    }

    function _cashInCourseShareStructHash(Types.CashInCourseShareWithSig memory params, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        if (block.timestamp > params.deadline) revert Errors.Edjuk8__InvalidSigDeadline();
        bytes32 structHash = keccak256(
            abi.encode(CASH_IN_COURSE_SHARE, params.user, params.courseId, params.sharesAmount, nonce, params.deadline)
        );
        return structHash;
    }

    function _deploySubCourseStructHash(Types.DeploySubCourseWithSig memory params, uint256 nonce)
        public
        view
        returns (bytes32)
    {
        if (block.timestamp > params.deadline) revert Errors.Edjuk8__InvalidSigDeadline();
        bytes32 structHash = keccak256(
            abi.encode(
                DEPLOY_SUB_COURSE,
                params.user,
                params.courseId,
                params.name,
                params.description,
                params.imageURI,
                params.price,
                params.focusAreas,
                nonce,
                params.deadline
            )
        );
        return structHash;
    }
}
