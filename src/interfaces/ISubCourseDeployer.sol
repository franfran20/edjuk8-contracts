// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Types} from "../utils/Types.sol";

interface ISubCourseDeployer {
    function getSubCourses(uint256 courseId) external view returns (Types.SubCourseDetail[] memory);
}
