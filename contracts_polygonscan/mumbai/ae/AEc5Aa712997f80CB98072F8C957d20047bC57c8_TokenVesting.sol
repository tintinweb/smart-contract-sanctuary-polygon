// contracts/TokenVesting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme.
 */
contract TokenVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(uint256 amount, address beneficiary);
    event NewBeneficiaryAdded(address beneficiary);

    // Everything is expressed in seconds, the same units as block.timestamp.
    struct VestingDetails {
        uint256 _start;
        uint256 _finish;
        uint256 _cliff;
        uint256 _releasesCount;
        uint256 _duration;
        uint256 _tokensAllocated;
        uint256 _tokensReleased;
    }

    mapping(address => VestingDetails) private _beneficiaryDetails;
    address[] private _beneficiaryNames;

    IERC20 private _token;
    // owner of this contract
    address private _owner;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until block.timestamp + cliff + duration * releasesCount.
     * By then all of the balance will have vested.
     * @param __token address of the token which should be vested
     * @param __beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param __cliff the duration in seconds from the current time at which point vesting starts
     * @param __releasesCount total amount of upcoming releases
     * @param __duration duration in seconds of each release
     * @param __tokensAllocated token allocated to this beneficiary
     */
    constructor(
        address __token,
        address[] memory __beneficiary,
        uint256[] memory __cliff,
        uint256[] memory __releasesCount,
        uint256[] memory __duration,
        uint256[] memory __tokensAllocated
    ) {
        require(
            __token != address(0),
            "TokenVesting: token is the zero address!"
        );

        _token = IERC20(__token);
        _owner = msg.sender;

        for (uint256 i = 0; i < __beneficiary.length; i++) {
            if (_beneficiaryDetails[__beneficiary[i]]._tokensAllocated == 0) {
                VestingDetails memory details;
                details._start = block.timestamp.add(__cliff[i]);
                details._finish = details._start.add(
                    __releasesCount[i].mul(__duration[i])
                );
                details._cliff = __cliff[i];
                details._releasesCount = __releasesCount[i];
                details._duration = __duration[i];
                details._tokensAllocated = __tokensAllocated[i];
                details._tokensReleased = 0;
                _beneficiaryDetails[__beneficiary[i]] = details;
                _beneficiaryNames.push(__beneficiary[i]);
            }
        }
    }

    // -----------------------------------------------------------------------
    // GETTERS
    // -----------------------------------------------------------------------

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiaries() public view returns (address[] memory) {
        return _beneficiaryNames;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start(address __beneficiary) public view returns (uint256) {
        return _beneficiaryDetails[__beneficiary]._start;
    }

    /**
     * @return the finish time of the token vesting.
     */
    function finish(address __beneficiary) public view returns (uint256) {
        return _beneficiaryDetails[__beneficiary]._finish;
    }

    /**
     * @return the cliff of the token vesting.
     */
    function cliff(address __beneficiary) public view returns (uint256) {
        return _beneficiaryDetails[__beneficiary]._cliff;
    }

    /**
     * @return the number of token releases.
     */
    function releasesCount(address __beneficiary)
        public
        view
        returns (uint256)
    {
        return _beneficiaryDetails[__beneficiary]._releasesCount;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration(address __beneficiary) public view returns (uint256) {
        return _beneficiaryDetails[__beneficiary]._duration;
    }

    /**
     * @return the number of tokens allocated.
     */
    function tokensAllocated(address __beneficiary)
        public
        view
        returns (uint256)
    {
        return _beneficiaryDetails[__beneficiary]._tokensAllocated;
    }

    /**
     * @return the amount of the tokens released.
     */
    function tokensReleased(address __beneficiary)
        public
        view
        returns (uint256)
    {
        return _beneficiaryDetails[__beneficiary]._tokensReleased;
    }

    /**
     * @return current balance of this vesting contract.
     */
    function contractBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @return the total tokens allocated for all the beneficiaries.
     */
    function totalTokensAllocated() public view returns (uint256) {
        uint256 totalTockens = 0;
        for (uint256 i = 0; i < _beneficiaryNames.length; i++) {
            address addr = _beneficiaryNames[i];
            totalTockens = totalTockens.add(
                _beneficiaryDetails[addr]._tokensAllocated
            );
        }
        return totalTockens;
    }

    /**
     * @return owner of this vesting contract.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function getAvailableTokens(address __beneficiary)
        public
        view
        returns (uint256)
    {
        require(
            _beneficiaryDetails[__beneficiary]._tokensAllocated > 0,
            "sender is not in the beneficiaries list!"
        );
        return _releasableAmount(__beneficiary);
    }

    // -----------------------------------------------------------------------
    // SETTERS
    // -----------------------------------------------------------------------

    /**
     * @notice Add a new beneficiary to the vesting scheme.
     */
    function addBeneficiary(
        address __beneficiary,
        uint256 __cliff,
        uint256 __releasesCount,
        uint256 __duration,
        uint256 __tokensAllocated
    ) public {
        require(msg.sender == _owner, "only owner can add new beneficiary!");
        require(
            _beneficiaryDetails[__beneficiary]._tokensAllocated == 0,
            "beneficiary already exists!"
        );

        VestingDetails memory details;
        details._start = block.timestamp.add(__cliff);
        details._finish = details._start.add(__releasesCount.mul(__duration));
        details._cliff = __cliff;
        details._releasesCount = __releasesCount;
        details._duration = __duration;
        details._tokensAllocated = __tokensAllocated;
        details._tokensReleased = 0;
        _beneficiaryDetails[__beneficiary] = details;
        _beneficiaryNames.push(__beneficiary);

        emit NewBeneficiaryAdded(__beneficiary);
    }

    /**
     * @notice Transfers vested tokens to all the beneficiaries.
     */
    function releaseForAll() public {
        require(msg.sender == _owner, "only owner can call this method!");

        for (uint256 i = 0; i < _beneficiaryNames.length; i++) {
            address addr = _beneficiaryNames[i];

            uint256 unreleased = _releasableAmount(addr);
            if (unreleased > 0) {
                _beneficiaryDetails[addr]._tokensReleased = _beneficiaryDetails[
                    addr
                ]._tokensReleased.add(unreleased);
                _token.safeTransfer(addr, unreleased);

                emit TokensReleased(unreleased, addr);
            }
        }
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        require(
            _beneficiaryDetails[msg.sender]._tokensAllocated > 0,
            "release: unauthorized sender!"
        );

        uint256 unreleased = _releasableAmount(msg.sender);
        require(unreleased > 0, "release: No tokens are due!");

        _beneficiaryDetails[msg.sender]._tokensReleased = _beneficiaryDetails[
            msg.sender
        ]._tokensReleased.add(unreleased);
        _token.safeTransfer(msg.sender, unreleased);

        emit TokensReleased(unreleased, msg.sender);
    }

    // -----------------------------------------------------------------------
    // INTERNAL
    // -----------------------------------------------------------------------

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount(address __beneficiary)
        private
        view
        returns (uint256)
    {
        return
            _vestedAmount(__beneficiary).sub(
                _beneficiaryDetails[__beneficiary]._tokensReleased
            );
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount(address __beneficiary)
        private
        view
        returns (uint256)
    {
        uint256 totalBalance = _beneficiaryDetails[__beneficiary]
            ._tokensAllocated;

        if (block.timestamp < _beneficiaryDetails[__beneficiary]._start) {
            return 0;
        } else if (
            block.timestamp >= _beneficiaryDetails[__beneficiary]._finish
        ) {
            return totalBalance;
        } else {
            uint256 timeLeftAfterStart = block.timestamp.sub(
                _beneficiaryDetails[__beneficiary]._start
            );
            uint256 availableReleases = timeLeftAfterStart.div(
                _beneficiaryDetails[__beneficiary]._duration
            );
            uint256 tokensPerRelease = totalBalance.div(
                _beneficiaryDetails[__beneficiary]._releasesCount
            );

            return availableReleases.mul(tokensPerRelease);
        }
    }
}