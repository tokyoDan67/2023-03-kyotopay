// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @title KyotoHub Tests
/// Version 1.1

import "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {Events} from "../src/libraries/Events.sol";
import {Fork} from "./reference/Fork.sol";
import {Helper} from "./reference/Helper.sol";
import {IWETH9} from "../src/interfaces/IWETH9.sol";
import {KyotoHub} from "../src/KyotoHub.sol";
import {MockERC20} from "./reference/MockERC20.sol";

contract Constructor is Test {
    function test_Constructor() public {
        KyotoHub kyotoHub = new KyotoHub();
        assertEq(kyotoHub.owner(), address(this));
    }
}

contract Setters is Test, Helper {
    KyotoHub kyotoHub;
    address mockERC20;

    function setUp() public {
        kyotoHub = new KyotoHub();
        mockERC20 = address(new MockERC20());
        kyotoHub.addToInputWhitelist(mockERC20);
        kyotoHub.addToOutputWhitelist(mockERC20);
    }

    function test_SetPreferences() public {
        uint96 _validSlippage = 100;

        DataTypes.Preferences memory _validPreferences = DataTypes.Preferences({
                tokenAddress: mockERC20, 
                slippageAllowed: _validSlippage
            });

        vm.startPrank(RANDOM_USER);

        vm.expectEmit(true, true, true, true);
        emit Events.PreferencesSet(RANDOM_USER, mockERC20, _validSlippage);

        kyotoHub.setPreferences(_validPreferences);

        vm.stopPrank();

        DataTypes.Preferences memory _recipientPreferences = kyotoHub.getRecipientPreferences(RANDOM_USER);

        assertEq(_recipientPreferences.tokenAddress, mockERC20);
        assertEq(_recipientPreferences.slippageAllowed, _validSlippage);
    }

    function test_SetPreferences_RevertIf_Paused() public {
        kyotoHub.pause();

        uint96 _validSlippage = 100;

        DataTypes.Preferences memory _validPreferences = DataTypes.Preferences({
                tokenAddress: mockERC20, 
                slippageAllowed: _validSlippage
            });
        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Pausable: paused");
        kyotoHub.setPreferences(_validPreferences);

        vm.stopPrank();
    }

    function test_SetPreferences_RevertIf_SlippagePreferenceZero() public {
        DataTypes.Preferences memory _invalidSlippage =
            DataTypes.Preferences({tokenAddress: mockERC20, slippageAllowed: 0});

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidRecipientSlippage.selector);
        kyotoHub.setPreferences(_invalidSlippage);

        vm.stopPrank();
    }

    // TO DO: Change decimals to a constants library
    function test_SetPreferences_RevertIf_SlippagePreferenceEqualToDecimals() public {
        uint256 decimals256 = kyotoHub.DECIMALS();
        uint96 invalidSlippage = uint96(decimals256);

        DataTypes.Preferences memory _invalidSlippage =
            DataTypes.Preferences({tokenAddress: mockERC20, slippageAllowed: invalidSlippage});

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidRecipientSlippage.selector);
        kyotoHub.setPreferences(_invalidSlippage);

        vm.stopPrank();
    }

    function test_SetPreferences_RevertIf_SlippagePreferenceGreaterThanDecimals() public {
        uint256 decimals256 = kyotoHub.DECIMALS();
        uint96 invalidSlippage = uint96(decimals256 + 1);

        DataTypes.Preferences memory _invalidSlippage =
            DataTypes.Preferences({tokenAddress: mockERC20, slippageAllowed: invalidSlippage});

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidRecipientSlippage.selector);
        kyotoHub.setPreferences(_invalidSlippage);

        vm.stopPrank();
    }

    /**
     * @dev DAI hasn't been added to whitelisted tokens yet
     */
    function test_SetPreference_RevertIf_InvalidTokenPreference() public {
        assertFalse(kyotoHub.isWhitelistedOutputToken(DAI_ADDRESS));

        DataTypes.Preferences memory _invalidToken =
            DataTypes.Preferences({tokenAddress: DAI_ADDRESS, slippageAllowed: 100});

        vm.startPrank(RANDOM_USER);

        vm.expectRevert(Errors.InvalidRecipientToken.selector);
        kyotoHub.setPreferences(_invalidToken);
    }

    function test_Pause_RevertIf_NotOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Ownable: caller is not the owner");
        kyotoHub.pause();

        vm.stopPrank();
    }

    function test_Unpause_RevertIf_NotOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Ownable: caller is not the owner");
        kyotoHub.unpause();

        vm.stopPrank();
    }

    function test_Pause() public {
        kyotoHub.pause();
    }

    function test_Unpause() public {
        kyotoHub.pause();
        kyotoHub.unpause();
    }
}

contract Admin is Test, Helper {
    using SafeERC20 for ERC20;

    KyotoHub kyotoHub;
    address mockERC20;

    function setUp() public {
        kyotoHub = new KyotoHub();
        mockERC20 = address(new MockERC20());
    }

    function test_AddToInputWhitelist() public {
        kyotoHub.addToInputWhitelist(mockERC20);
        assertTrue(kyotoHub.isWhitelistedInputToken(mockERC20));
    }

    function test_AddToOutputWhitelist() public {
        kyotoHub.addToOutputWhitelist(mockERC20);
        assertTrue(kyotoHub.isWhitelistedOutputToken(mockERC20));
    }

    function test_AddToInputWhiteList_RevertIf_NotOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Ownable: caller is not the owner");
        kyotoHub.addToInputWhitelist(mockERC20);

        vm.stopPrank();
    }

    function test_AddToOutputWhitelist_RevertIf_NotOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Ownable: caller is not the owner");
        kyotoHub.addToOutputWhitelist(mockERC20);

        vm.stopPrank();
    }

    function test_addToInputWhiteList_RevertIf_ZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        kyotoHub.addToInputWhitelist(address(0));

        vm.stopPrank();
    }

    function test_addToOutputWhiteList_RevertIf_ZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        kyotoHub.addToOutputWhitelist(address(0));

        vm.stopPrank();
    }

    function test_revokeFromInputWhitelist() public {
        kyotoHub.addToInputWhitelist(mockERC20);
        assertTrue(kyotoHub.isWhitelistedInputToken(mockERC20));

        kyotoHub.revokeFromInputWhitelist(mockERC20);
        assertFalse(kyotoHub.isWhitelistedInputToken(mockERC20));
    }

    function test_revokeFromOutputWhitelist() public {
        kyotoHub.addToOutputWhitelist(mockERC20);
        assertTrue(kyotoHub.isWhitelistedOutputToken(mockERC20));

        kyotoHub.revokeFromOutputWhitelist(mockERC20);
        assertFalse(kyotoHub.isWhitelistedOutputToken(mockERC20));
    }

    function test_revokeFromInputWhiteList_RevertIf_NotOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Ownable: caller is not the owner");
        kyotoHub.revokeFromInputWhitelist(mockERC20);

        vm.stopPrank();
    }

    function test_revokeFromOutputWhiteList_RevertIf_NotOwner() public {
        vm.startPrank(RANDOM_USER);

        vm.expectRevert("Ownable: caller is not the owner");
        kyotoHub.revokeFromOutputWhitelist(mockERC20);

        vm.stopPrank();
    }

    function test_revokeFromInputWhiteListRevertIf_ZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        kyotoHub.revokeFromInputWhitelist(address(0));
    }

    function test_revokeFromOutputWhiteListRevertIf_ZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        kyotoHub.revokeFromOutputWhitelist(address(0));
    }
}
