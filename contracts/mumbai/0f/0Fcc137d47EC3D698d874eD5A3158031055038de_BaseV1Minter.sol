// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

interface ve {
    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function create_lock_for(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

interface underlying {
    function approve(address spender, uint256 value) external returns (bool);

    function mint(address, uint256) external;

    function totalSupply() external view returns (uint256);

    function grossSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);
}

interface voter {
    function notifyRewardAmount(uint256 amount) external;
}

interface ve_dist {
    function checkpoint_token() external;

    function checkpoint_total_supply() external;
}

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract BaseV1Minter {
    uint256 internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint256 internal constant emission = 98;
    uint256 internal constant tail_emission = 2;
    uint256 internal constant target_base = 100; // 2% per week target emission
    uint256 internal constant tail_base = 1000; // 0.2% per week target emission
    underlying public immutable _token;
    voter public immutable _voter;
    ve public immutable _ve;
    uint256 public weekly = 20000000e18;
    uint256 public active_period;
    // uint256 internal constant lock = 86400 * 7 * 52 * 4;

    address internal initializer;

    event Mint(
        address indexed sender,
        uint256 weekly,
        uint256 circulating_supply,
        uint256 circulating_emission
    );

    constructor(
        address __voter, // the voting & distribution system
        address __ve // the ve(3,3) system that will be locked into
    ) {
        initializer = msg.sender;
        _token = underlying(ve(__ve).token());
        _voter = voter(__voter);
        _ve = ve(__ve);
        // active_period = ((block.timestamp + (2 * week)) / week) * week;
        active_period = block.timestamp + week;
    }

    // function initialize(
    //     address[] memory claimants,
    //     uint256[] memory amounts,
    //     uint256 max // sum amounts / max = % ownership of top protocols, so if initial 20m is distributed, and target is 25% protocol ownership, then max - 4 x 20m = 80m
    // ) external {
    //     require(initializer == msg.sender);
    //     _token.mint(address(this), max);
    //     _token.approve(address(_ve), type(uint256).max);
    //     for (uint256 i = 0; i < claimants.length; i++) {
    //         _ve.create_lock_for(amounts[i], lock, claimants[i]);
    //     }
    //     initializer = address(0);
    //     active_period = ((block.timestamp + week) / week) * week;
    // }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint256) {
        return _token.grossSupply() - _token.totalSupply();
    }

    // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint256) {
        return
            (weekly * emission * circulating_supply()) /
            target_base /
            _token.grossSupply();
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint256) {
        return Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint256) {
        return (circulating_supply() * tail_emission) / tail_base;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint256 _minted) public view returns (uint256) {
        return (_token.totalSupply() * _minted) / _token.grossSupply();
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (bool) {
        uint256 _period = active_period;
        if (block.timestamp >= _period + week) {
            // only trigger if new week
            _period = (block.timestamp / week) * week;
            active_period = _period;
            weekly = weekly_emission();

            uint256 _balanceOf = _token.balanceOf(address(this));
            if (_balanceOf < weekly) {
                _token.mint(address(this), weekly - _balanceOf);
            }

            _token.approve(address(_voter), weekly);
            _voter.notifyRewardAmount(weekly);

            emit Mint(
                msg.sender,
                weekly,
                circulating_supply(),
                circulating_emission()
            );
            return true;
        }
        return false;
    }
}