// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {NGNs} from "../src/NGNs.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployNGNs is Script {
    function run() external returns (NGNs, address, address) {
        return deploy();
    }

    function deploy() public returns (NGNs, address, address) {
        (address admin, uint256 adminKey) = makeAddrAndKey("admin");
        (address treasuryAdmin,) = makeAddrAndKey("treasuryAdmin");

        if (block.chainid == 31337) {
            vm.startBroadcast(adminKey);

            NGNs implementation = new NGNs();

            bytes memory initData = abi.encodeWithSelector(implementation.initialize.selector);

            ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
            NGNs ngns = NGNs(address(proxy));
            ngns.grantRole(keccak256("TREASURY_ROLE"), treasuryAdmin);

            vm.stopBroadcast();

            return (ngns, admin, treasuryAdmin);
        } else {
            vm.startBroadcast();
            NGNs implementation = new NGNs();

            bytes memory initData = abi.encodeWithSelector(implementation.initialize.selector);

            ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
            NGNs ngns = NGNs(address(proxy));
            console.log(address(ngns));

            console.log("proxy", address(proxy));
            vm.stopBroadcast();

            return (ngns, admin, treasuryAdmin);
        }
    }
}
