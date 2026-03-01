// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {NGNs} from "../src/NGNs.sol";
import {DeployNGNs} from "../script/DeployNGNs.s.sol";

contract TestNGNs is Test {
    NGNs private ngns;
    address private TEST_OWNER;
    address private TEST_TREASURY_ADMIN;
    address private TEST_USER = makeAddr("user");

    bytes32 private constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    uint256 private constant MINT_AMOUNT = 1_000_000e6;

    function setUp() external {
        DeployNGNs deploy = new DeployNGNs();
        (ngns, TEST_OWNER, TEST_TREASURY_ADMIN) = deploy.run();

        vm.startPrank(TEST_TREASURY_ADMIN);
        ngns.mint(TEST_OWNER, MINT_AMOUNT);
        ngns.mint(TEST_TREASURY_ADMIN, MINT_AMOUNT);
        ngns.mint(TEST_USER, MINT_AMOUNT);
        vm.stopPrank();
    }

    // ===============================================
    // INITIALIZATION
    // ===============================================

    function test_Already_Initialized() public {
        vm.expectRevert();
        ngns.initialize();
    }

    function test_Decimals_Are_Six() public view {
        assertEq(ngns.decimals(), 6);
    }

    function test_Token_Name_And_Symbol() public view {
        assertEq(ngns.name(), "Salva NGNs");
        assertEq(ngns.symbol(), "NGNs");
    }

    // ===============================================
    // ROLES
    // ===============================================

    function test_Roles() public view {
        assertTrue(ngns.hasRole(ngns.DEFAULT_ADMIN_ROLE(), TEST_OWNER));
        assertTrue(ngns.hasRole(TREASURY_ROLE, TEST_TREASURY_ADMIN));
    }

    function test_Only_Treasury_Can_Mint(address _random) public {
        vm.assume(_random != TEST_TREASURY_ADMIN);
        vm.prank(_random);
        vm.expectRevert();
        ngns.mint(TEST_USER, 100e6);
    }

    function test_Only_Treasury_Can_Burn(address _random) public {
        vm.assume(_random != TEST_TREASURY_ADMIN);
        vm.prank(_random);
        vm.expectRevert();
        ngns.burn(TEST_USER, 100e6);
    }

    function test_Only_Admin_Can_Freeze(address _random) public {
        vm.assume(_random != TEST_OWNER);
        vm.prank(_random);
        vm.expectRevert();
        ngns.freezeAccount(TEST_USER);
    }

    function test_Only_Admin_Can_Unfreeze(address _random) public {
        vm.assume(_random != TEST_OWNER);

        vm.prank(TEST_OWNER);
        ngns.freezeAccount(TEST_USER);

        vm.prank(_random);
        vm.expectRevert();
        ngns.unfreezeAccount(TEST_USER);
    }

    function test_Only_Admin_Can_Set_Operational_Status(address _random) public {
        vm.assume(_random != TEST_OWNER);
        vm.prank(_random);
        vm.expectRevert();
        ngns.setOperationalStatus(false);
    }

    function test_Only_Admin_Can_Upgrade(address _random) public {
        vm.assume(_random != TEST_OWNER);
        vm.prank(_random);
        vm.expectRevert();
        ngns.upgradeToAndCall(address(this), "");
    }

    // ===============================================
    // MINT & BURN
    // ===============================================

    function test_Mint() public {
        uint256 balanceBefore = ngns.balanceOf(TEST_USER);
        uint256 amount = 500e6;

        vm.prank(TEST_TREASURY_ADMIN);
        ngns.mint(TEST_USER, amount);

        assertEq(ngns.balanceOf(TEST_USER), balanceBefore + amount);
    }

    function test_Burn() public {
        uint256 balanceBefore = ngns.balanceOf(TEST_USER);
        uint256 amount = 500e6;

        vm.prank(TEST_TREASURY_ADMIN);
        ngns.burn(TEST_USER, amount);

        assertEq(ngns.balanceOf(TEST_USER), balanceBefore - amount);
    }

    // ===============================================
    // TRANSFER
    // ===============================================

    function test_Transfer() public {
        uint256 amount = 100e6;
        uint256 senderBefore = ngns.balanceOf(TEST_OWNER);
        uint256 receiverBefore = ngns.balanceOf(TEST_USER);

        vm.prank(TEST_OWNER);
        ngns.transfer(TEST_USER, amount);

        assertEq(ngns.balanceOf(TEST_OWNER), senderBefore - amount);
        assertEq(ngns.balanceOf(TEST_USER), receiverBefore + amount);
    }

    function test_Approve_And_TransferFrom() public {
        uint256 amount = 100e6;

        vm.prank(TEST_OWNER);
        ngns.approve(TEST_USER, amount);

        assertEq(ngns.allowance(TEST_OWNER, TEST_USER), amount);

        uint256 ownerBefore = ngns.balanceOf(TEST_OWNER);
        uint256 userBefore = ngns.balanceOf(TEST_USER);

        vm.prank(TEST_USER);
        ngns.transferFrom(TEST_OWNER, TEST_USER, amount);

        assertEq(ngns.balanceOf(TEST_OWNER), ownerBefore - amount);
        assertEq(ngns.balanceOf(TEST_USER), userBefore + amount);
        assertEq(ngns.allowance(TEST_OWNER, TEST_USER), 0);
    }

    // ===============================================
    // FREEZE / BLACKLIST
    // ===============================================

    function test_Freeze_And_Unfreeze_Account() public {
        vm.prank(TEST_OWNER);
        ngns.freezeAccount(TEST_USER);
        assertTrue(ngns.isAccountFrozen(TEST_USER));

        vm.prank(TEST_OWNER);
        ngns.unfreezeAccount(TEST_USER);
        assertFalse(ngns.isAccountFrozen(TEST_USER));
    }

    function test_Frozen_Account_Cannot_Send() public {
        vm.prank(TEST_OWNER);
        ngns.freezeAccount(TEST_USER);

        vm.prank(TEST_USER);
        vm.expectRevert();
        ngns.transfer(TEST_OWNER, 100e6);
    }

    function test_Frozen_Account_Cannot_Receive() public {
        vm.prank(TEST_OWNER);
        ngns.freezeAccount(TEST_USER);

        vm.prank(TEST_OWNER);
        vm.expectRevert();
        ngns.transfer(TEST_USER, 100e6);
    }

    // ===============================================
    // OPERATIONAL STATUS (CIRCUIT BREAKER)
    // ===============================================

    function test_Pause_Blocks_Transfers() public {
        vm.prank(TEST_OWNER);
        ngns.setOperationalStatus(false);
        assertFalse(ngns.isOperational());

        vm.prank(TEST_USER);
        vm.expectRevert();
        ngns.transfer(TEST_OWNER, 100e6);
    }

    function test_Pause_Blocks_Approve() public {
        vm.prank(TEST_OWNER);
        ngns.setOperationalStatus(false);

        vm.prank(TEST_USER);
        vm.expectRevert();
        ngns.approve(TEST_OWNER, 100e6);
    }

    function test_Pause_Blocks_TransferFrom() public {
        uint256 amount = 100e6;

        vm.prank(TEST_OWNER);
        ngns.approve(TEST_USER, amount);

        vm.prank(TEST_OWNER);
        ngns.setOperationalStatus(false);

        vm.prank(TEST_USER);
        vm.expectRevert();
        ngns.transferFrom(TEST_OWNER, TEST_USER, amount);
    }

    function test_Admin_Can_Transfer_While_Paused() public {
        uint256 amount = 100e6;
        address recipient = makeAddr("recipient");

        vm.prank(TEST_OWNER);
        ngns.setOperationalStatus(false);

        vm.prank(TEST_OWNER);
        ngns.transfer(recipient, amount);

        assertEq(ngns.balanceOf(recipient), amount);
    }

    function test_Pause_Blocks_Mint() public {
        vm.prank(TEST_OWNER);
        ngns.setOperationalStatus(false);

        vm.prank(TEST_TREASURY_ADMIN);
        vm.expectRevert();
        ngns.mint(TEST_USER, 100e6);
    }

    function test_Resume_Operations() public {
        vm.prank(TEST_OWNER);
        ngns.setOperationalStatus(false);
        assertFalse(ngns.isOperational());

        vm.prank(TEST_OWNER);
        ngns.setOperationalStatus(true);
        assertTrue(ngns.isOperational());

        vm.prank(TEST_USER);
        bool success = ngns.transfer(TEST_OWNER, 100e6);
        assertTrue(success);
    }
}
