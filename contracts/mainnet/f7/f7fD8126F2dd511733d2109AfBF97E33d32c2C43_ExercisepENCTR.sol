// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5; // solhint-disable-line

import "../types/EncountrAccessControlled.sol";

import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/IENCTR.sol";
import "../interfaces/IpENCTR.sol";
import "../interfaces/ITreasury.sol";

contract ExercisepENCTR is EncountrAccessControlled {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using SafeERC20 for IENCTR;
    using SafeERC20 for IpENCTR;

    IpENCTR public immutable pENCTR;
    IENCTR public immutable ENCTR; // solhint-disable-line var-name-mixedcase
    IERC20 public immutable DAI; // solhint-disable-line var-name-mixedcase
    ITreasury public immutable treasury;

    struct Term {
        uint percent; // 4 decimals ( 5000 = 0.5% )
        uint claimed;
        uint max;
    }
    mapping(address => Term) public terms;
    mapping(address => address) public walletChange;

    constructor(
        address _ENCTR, // solhint-disable-line var-name-mixedcase
        address _pENCTR,
        address _DAI, // solhint-disable-line var-name-mixedcase
        address _treasury,
        address _authority
    ) EncountrAccessControlled(IEncountrAuthority(_authority)) {
        require(_ENCTR != address(0), "zero address.");
        ENCTR = IENCTR(_ENCTR);

        require(_pENCTR != address(0), "zero address.");
        pENCTR = IpENCTR(_pENCTR);

        require(_DAI != address(0), "zero address.");
        DAI = IERC20(_DAI);

        require(_treasury != address(0), "zero address.");
        treasury = ITreasury(_treasury);
    }

    // Sets terms for a new wallet
    function setTerms(address _vester, uint _rate, uint _claimed, uint _max) external onlyGovernor() {
        require(_max >= terms[ _vester ].max, "cannot lower amount claimable");
        require(_rate >= terms[ _vester ].percent, "cannot lower vesting rate");
        require(_claimed >= terms[ _vester ].claimed, "cannot lower claimed");
        require(pENCTR.isApprovedSeller(_vester), "the vester has not been approved");

        terms[_vester] = Term({
            percent: _rate,
            claimed: _claimed,
            max: _max
        });
    }

    // Allows wallet to redeem pENCTR for ENCTR
    function exercise(uint _amount) external {
        Term memory info = terms[msg.sender];

        require(redeemable(info) >= _amount, "Not enough vested");
        require(info.max.sub(info.claimed) >= _amount, "Claimed over max");

        DAI.safeTransferFrom(msg.sender, address(this), _amount);
        pENCTR.safeTransferFrom(msg.sender, address(this), _amount);

        DAI.approve(address(treasury), _amount);
        uint toSend = treasury.deposit(_amount, address(DAI), 0);

        terms[msg.sender].claimed = info.claimed.add(_amount);

        ENCTR.safeTransfer(msg.sender, toSend);
    }

    // Allows wallet owner to transfer rights to a new address
    function pushWalletChange(address _newWallet) external {
        require(msg.sender != _newWallet, "must specify a new wallet");
        require(terms[msg.sender].percent != 0, "not a participating wallet");
        walletChange[msg.sender] = _newWallet;
    }

    // Allows wallet to pull rights from an old address
    function pullWalletChange(address _oldWallet) external {
        require(walletChange[_oldWallet] == msg.sender, "wallet did not push");

        walletChange[_oldWallet] = address(0);
        terms[msg.sender] = terms[_oldWallet];
        delete terms[_oldWallet];
    }

    // Amount a wallet can redeem based on current supply
    function redeemableFor(address _vester) public view returns (uint) {
        return redeemable(terms[_vester]);
    }

    function redeemable(Term memory _info) internal view returns (uint) {
        return (ENCTR.totalSupply().mul(_info.percent).div(1000000)).sub(_info.claimed);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IEncountrAuthority.sol";

abstract contract EncountrAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IEncountrAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IEncountrAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IEncountrAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IEncountrAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IENCTR is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IpENCTR is IERC20 {
    function isApprovedSeller(address account_) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);

    function isPermitted(uint _status, address _address) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IEncountrAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}