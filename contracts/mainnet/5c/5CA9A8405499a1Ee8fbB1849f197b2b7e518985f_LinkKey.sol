// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Timers.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract LinkKey is ERC20,Ownable,Pausable {

    using Timers for Timers.Timestamp;
    using SafeMath for uint256;

    mapping(address => bool) public minter;

    address public userCollectAddress;
    address public teamCollectAddress;
    address public investorCollectAddress;
    address public bidderCollectAddress;

    uint256 public totalShare;
    uint256 public userShare;
    uint256 public teamShare;
    uint256 public investorShare;
    uint256 public bidderShare;

    uint256 public releaseAmount;

    Timers.Timestamp public releaseTime;

    constructor(string memory name_, string memory symbol_,
        uint64 deadline_, address userCollectAddress_,
        address teamCollectAddress_, address investorCollectAddress_, address bidderCollectAddress_,
        uint256 releaseAmount_) ERC20(name_,symbol_) Pausable(){

        releaseTime.setDeadline(deadline_);

        userCollectAddress = userCollectAddress_;
        teamCollectAddress = teamCollectAddress_;
        investorCollectAddress = investorCollectAddress_;
        bidderCollectAddress = bidderCollectAddress_;

        userShare = 5;
        teamShare = 1;
        investorShare = 3;
        bidderShare = 1;
        setTotalShare();

        releaseAmount = releaseAmount_;
    }

    modifier releasing(){
        require(releaseTime.isPending(), "token release stop, permission denied.");
        _;
    }

    modifier releaseStop() {
        require(releaseTime.isExpired(), "token releasing, permission denied.");
        _;
    }

    function mint() public returns(bool){
        if( (!minter[_msgSender()]) || releaseTime.isExpired() || paused() || totalShare <= 0){
            return false;
        }

        uint256 userCollectToken = releaseAmount.mul(1 ether).mul(userShare).div(totalShare);
        uint256 teamCollectToken = releaseAmount.mul(1 ether).mul(teamShare).div(totalShare);
        uint256 investorCollectToken = releaseAmount.mul(1 ether).mul(investorShare).div(totalShare);
        uint256 bidderCollectToken = releaseAmount.mul(1 ether).mul(bidderShare).div(totalShare);

        _mint(userCollectAddress, userCollectToken);
        _mint(teamCollectAddress, teamCollectToken);
        _mint(investorCollectAddress, investorCollectToken);
        _mint(bidderCollectAddress, bidderCollectToken);
        return true;
    }

    function setTotalShare() internal{
        totalShare = userShare + teamShare + investorShare +bidderShare;
    }

    function setUserShare(uint256 userShare_) public releaseStop onlyOwner{
        userShare = userShare_;
        setTotalShare();
    }

    function setTeamShare(uint256 teamShare_) public releaseStop onlyOwner{
        teamShare = teamShare_;
        setTotalShare();
    }

    function setInvestorShare(uint256 investorShare_) public releaseStop onlyOwner{
        investorShare = investorShare_;
        setTotalShare();
    }

    function setBidderShare(uint256 bidderShare_) public releaseStop onlyOwner{
        bidderShare = bidderShare_;
        setTotalShare();
    }

    function setReleaseTime(uint64 deadline_) public releaseStop onlyOwner{
        releaseTime.setDeadline(deadline_);
    }

    function setUserCollectAddress(address userCollectAddress_) public onlyOwner{
        userCollectAddress = userCollectAddress_;
    }

    function setTeamCollectAddress(address teamCollectAddress_) public onlyOwner{
        teamCollectAddress = teamCollectAddress_;
    }

    function setInvestorCollectAddress(address investorCollectAddress_) public onlyOwner{
        investorCollectAddress = investorCollectAddress_;
    }

    function setBidderCollectAddress(address bidderCollectAddress_) public onlyOwner{
        bidderCollectAddress = bidderCollectAddress_;
    }

    function setMinter(address minter_) public onlyOwner{
        minter[minter_] = true;
    }

    function removeMinter(address minter_) public onlyOwner{
        minter[minter_] = false;
    }

    function burn(uint256 amount_) public whenNotPaused{
        _burn(_msgSender(), amount_);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public whenNotPaused{
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
    }
        _burn(account, amount);
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }
}