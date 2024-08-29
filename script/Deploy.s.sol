// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {CourseHandler} from "../src/CourseHandler.sol";
import {Edjuk8Token} from "../src/Edjuk8Token.sol";
import {ShareMarketPlace} from "../src/ShareMarketPlace.sol";
import {SubCourse} from "../src/SubCourse.sol";
import {SubCourseDeployer} from "../src/SubCourseDeployer.sol";

// rpc url - https://rpc.open-campus-codex.gelato.digital

contract Deploy is Script {
    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast();
        console.log("Deploying Contracts...");

        Edjuk8Token edjuk8Token = new Edjuk8Token();
        console.log("Edjuk8 Token: ", address(edjuk8Token));

        CourseHandler courseHandler = new CourseHandler(address(edjuk8Token));
        console.log("Course Handler: ", address(courseHandler));

        SubCourseDeployer subCourseDeployer = new SubCourseDeployer(address(courseHandler), address(edjuk8Token));
        console.log("SubCourse Deployer: ", address(subCourseDeployer));

        ShareMarketPlace shareMarketPlace = new ShareMarketPlace(address(courseHandler), address(edjuk8Token));
        console.log("Share MarketPlace: ", address(shareMarketPlace));

        courseHandler.setCourseMarketPlace(address(shareMarketPlace));
        courseHandler.setSubCourseDeployer(address(subCourseDeployer));

        vm.stopBroadcast();
    }
}

// Deploying Contracts...
//   Edjuk8 Token:  0x1E94F3409d89bc5eF67724fE4F6f104AdBEA0D19
//   Course Handler:  0xf413E7646F4EEB3619c86658031d1197BB26d3e1
//   SubCourse Deployer:  0x9851a9C83Bd9212d9e95b67481e7df10bCe425d0
//   Share MarketPlace:  0xAC90cdbBb9AD436bDcF9693706dd900702105E55
