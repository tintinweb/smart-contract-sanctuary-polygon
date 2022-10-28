/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/operator.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.7.6;

////// src/lib/casten-auth/src/auth.sol
// Copyright (C) Casten 2022, based on MakerDAO dss https://github.com/makerdao/dss
/* pragma solidity >=0.5.15; */

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

////// src/operator.sol
/* pragma solidity >=0.7.6; */

/* import "./lib/casten-auth/src/auth.sol"; */

interface TrancheLike_3 {
    function supplyOrder(address usr, uint currencyAmount) external;
    function redeemOrder(address usr, uint tokenAmount) external;
    function disburse(address usr) external returns (uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken);
    function disburse(address usr, uint endEpoch) external returns (uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken);
    function currency() external view returns (address);
}

interface RestrictedTokenLike {
    function hasMember(address) external view returns (bool);
}

interface EIP2612PermitLike {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface DaiPermitLike {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

contract Operator is Auth {
    TrancheLike_3 public tranche;
    RestrictedTokenLike public token;

    // Events
    event SupplyOrder(uint indexed amount, address indexed usr);
    event RedeemOrder(uint indexed amount, address indexed usr);
    event Depend(bytes32 indexed contractName, address addr);
    event Disburse(address indexed usr);

    constructor(address tranche_) {
        tranche = TrancheLike_3(tranche_);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // only investors that are on the memberlist can disburse
    function disburse() external
        returns(uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken)
    {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        emit Disburse(msg.sender);
        return tranche.disburse(msg.sender);
    }

    function disburse(uint endEpoch) external
        returns(uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken)
    {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        emit Disburse(msg.sender);
        return tranche.disburse(msg.sender, endEpoch);
    }

    // only investors that are on the memberlist can submit supplyOrders
    function supplyOrder(uint amount) public {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        tranche.supplyOrder(msg.sender, amount);
        emit SupplyOrder(amount, msg.sender);
    }

    // only investors that are on the memberlist can submit redeemOrders
    function redeemOrder(uint amount) public {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        tranche.redeemOrder(msg.sender, amount);
        emit RedeemOrder(amount, msg.sender);
    }

    // --- Permit Support ---
    function supplyOrderWithDaiPermit(uint amount, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        DaiPermitLike(tranche.currency()).permit(msg.sender, address(tranche), nonce, expiry, true, v, r, s);
        supplyOrder(amount);
    }
    function supplyOrderWithPermit(uint amount, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        EIP2612PermitLike(tranche.currency()).permit(msg.sender, address(tranche), value, deadline, v, r, s);
        supplyOrder(amount);
    }
    function redeemOrderWithPermit(uint amount, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        EIP2612PermitLike(address(token)).permit(msg.sender, address(tranche), value, deadline, v, r, s);
        redeemOrder(amount);
    }

        // sets the dependency to another contract
    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "tranche") { tranche = TrancheLike_3(addr); }
        else if (contractName == "token") { token = RestrictedTokenLike(addr); }
        else revert();
        emit Depend(contractName, addr);
    }
}
/**
source bin/test/setup_local_config.sh
make build
 */