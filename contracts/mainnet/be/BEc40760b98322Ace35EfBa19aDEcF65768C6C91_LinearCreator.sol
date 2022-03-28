// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ILinearCreator.sol";
import "./LinearVesting.sol";

contract LinearCreator is ILinearCreator{
    address[] public override allVestings; // all vestings created
    
    address public override owner = msg.sender;
    
    modifier onlyOwner{
        require(owner == msg.sender, "!owner");
        _;
    }
    
    /**
     * @dev Get total number of vestings created
     */
    function allVestingsLength() public override view returns (uint) {
        return allVestings.length;
    }
    
    /**
     * @dev Create new vesting to distribute token
     * @param _token Token project address
     * @param _tgeDatetime TGE datetime in epoch
     * @param _tgeRatio_d2 TGE ratio in percent (2 decimal)
     * @param _startEndLinearDatetime Start & end Linear datetime in epoch
     */
    function createVesting(
        address _token,
        uint32 _tgeDatetime,
        uint16 _tgeRatio_d2,
        uint32[2] calldata _startEndLinearDatetime
    ) public override onlyOwner returns(address vesting){
        vesting = address(new LinearVesting());

        allVestings.push(vesting);
        
        LinearVesting(vesting).initialize(
            _token,
            _tgeDatetime,
            _tgeRatio_d2,
            _startEndLinearDatetime
        );
        
        emit VestingCreated(vesting, allVestings.length - 1);
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) public override onlyOwner{
        require(_newOwner != address(0) && _newOwner != owner, "!good");
        owner = _newOwner;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ILinearCreator{
    event VestingCreated(address indexed vesting, uint index);
    
    function owner() external  view returns (address);
    
    function allVestingsLength() external view returns(uint);
    function allVestings(uint) external view returns(address);
    
    function createVesting(address, uint32, uint16, uint32[2] calldata) external returns (address);
    
    function transferOwnership(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";
import "./ILinearCreator.sol";

contract LinearVesting{
    bool private initialized;
    bool public isPaused;

    uint128 public sold;
    uint32 public tgeDatetime;
    uint16 public tgeRatio_d2;
    uint32 public startLinear;
    uint32 public endLinear;
    
    address public immutable creator = msg.sender;
    address public owner = tx.origin;
    address public token;

    address[] public buyers;

    struct Bought{
        uint16 buyerIndex;
        uint128 purchased;
        uint128 linearPerSecond;
        bool tgeClaimed;
        uint32 lastClaimed;
        uint128 claimed;
    }
    
    mapping(address => Bought) public invoice;
    
    modifier onlyOwner{
        require(msg.sender == owner, "!owner");
        _;
    }
    
    /**
     * @dev Initialize vesting token distribution
     * @param _token Token project address
     * @param _tgeDatetime TGE datetime in epoch
     * @param _tgeRatio_d2 TGE ratio in percent (2 decimal)
     * @param _startEndLinearDatetime Start & end Linear datetime in epoch
     */
    function initialize(
        address _token,
        uint32 _tgeDatetime,
        uint16 _tgeRatio_d2,
        uint32[2] calldata _startEndLinearDatetime
    ) external {
        require(!initialized, "Initialized");
        require(msg.sender == creator, "!creator");

        _setToken(_token);
        if(_tgeDatetime > 0 && _tgeRatio_d2 > 0){
            _setTgeDatetime(_tgeDatetime);
            _setTgeRatio(_tgeRatio_d2);
        }
        _setStartEndLinearDatetime(_startEndLinearDatetime);

        initialized = true;
    }

    /**
     * @dev Get length of buyer
     */
    function getBuyerLength() external view returns (uint){
        return buyers.length;
    }

    /**
     * @dev Get linear started status
     */
    function linearStarted() public view returns(bool){
        return (startLinear < block.timestamp) ? true : false;
    }

    /**
     * @dev Token claim
     */
    function claimToken() external {
        require(!isPaused && tgeDatetime <= block.timestamp && token != address(0) && IERC20(token).balanceOf(address(this)) > 0, "!started");
        require(invoice[msg.sender].purchased > 0 && invoice[msg.sender].lastClaimed <= endLinear, "!good");
        
        if( tgeDatetime > 0 && invoice[msg.sender].tgeClaimed && !linearStarted() ||
            tgeDatetime == 0 && !linearStarted()
        ) revert("wait");

        uint128 amountToClaim;
        if(tgeDatetime > 0 && !invoice[msg.sender].tgeClaimed){
            amountToClaim = (invoice[msg.sender].purchased * tgeRatio_d2) / 10000;
            invoice[msg.sender].tgeClaimed = true;
        }

        if(linearStarted()){
            if (invoice[msg.sender].lastClaimed < startLinear && block.timestamp >= endLinear){
                amountToClaim += (invoice[msg.sender].purchased * (10000 - tgeRatio_d2)) / 10000;
            } else{
                uint32 lastClaimed = invoice[msg.sender].lastClaimed < startLinear ? startLinear : invoice[msg.sender].lastClaimed;
                uint32 claimNow = block.timestamp >= endLinear ? endLinear : uint32(block.timestamp);
                amountToClaim += uint128((claimNow - lastClaimed) * invoice[msg.sender].linearPerSecond);
            }
        }

        require(IERC20(token).balanceOf(address(this)) >= amountToClaim, "insufficient");
        
        invoice[msg.sender].claimed += amountToClaim;
        invoice[msg.sender].lastClaimed = uint32(block.timestamp);

        TransferHelper.safeTransfer(address(token), msg.sender, amountToClaim);        
    }

    /**
     * @dev Set token project
     * @param _token Token project address
     */
    function _setToken(address _token) private {
        require(_token != address(0) && token != _token, "!good");
        token = _token;
    }

    /**
     * @dev Set TGE datetime
     * @param _tgeDatetime TGE datetime in epoch
     */
    function _setTgeDatetime(uint32 _tgeDatetime) private {
        require(tgeDatetime != _tgeDatetime, "!good");
        tgeDatetime = _tgeDatetime;
    }

    /**
     * @dev Set TGE ratio
     * @param _tgeRatio_d2 TGE ratio in percent (2 decimal)
     */
    function _setTgeRatio(uint16 _tgeRatio_d2) private {
        require(tgeRatio_d2 != _tgeRatio_d2, "!good");
        tgeRatio_d2 = _tgeRatio_d2;
    }

    /**
     * @dev Set start & end linear datetime
     * @param _startEndLinearDatetime Start & end Linear datetime in epoch
     */
    function _setStartEndLinearDatetime(uint32[2] calldata _startEndLinearDatetime) private {
        require(block.timestamp < _startEndLinearDatetime[0] && _startEndLinearDatetime[0] < _startEndLinearDatetime[1], "!good");
        startLinear = _startEndLinearDatetime[0];
        endLinear = _startEndLinearDatetime[1];
    }

    /**
     * @dev Insert new buyers & purchases
     * @param _buyer Buyer address
     * @param _purchased Buyer purchase
     */
    function newBuyers(address[] calldata _buyer, uint128[] calldata _purchased) external onlyOwner {
        require(_buyer.length == _purchased.length, "!good");

        for(uint16 i=0; i<_buyer.length; i++){
            if(_buyer[i] == address(0) || _purchased[i] == 0) continue;

            if(invoice[_buyer[i]].purchased == 0){
                buyers.push(_buyer[i]);
                invoice[_buyer[i]].buyerIndex = uint16(buyers.length - 1);
            }

            invoice[_buyer[i]].purchased += _purchased[i];
            invoice[_buyer[i]].linearPerSecond = ((invoice[_buyer[i]].purchased * (10000 - tgeRatio_d2)) / 10000) / (endLinear - startLinear);
            sold += _purchased[i];
        }
    }

    /**
     * @dev Replace buyers address
     * @param _oldBuyer Old address
     * @param _newBuyer New purchase
     */
    function replaceBuyers(address[] calldata _oldBuyer, address[] calldata _newBuyer) external onlyOwner {
        require(_oldBuyer.length == _newBuyer.length && buyers.length > 0, "!good");

        for(uint16 i=0; i<_oldBuyer.length; i++){
            if( invoice[_oldBuyer[i]].purchased == 0 ||
                _oldBuyer[i] == address(0) ||
                _newBuyer[i] == address(0)
            ) continue;

            buyers[invoice[_oldBuyer[i]].buyerIndex] = _newBuyer[i];

            invoice[_newBuyer[i]] = invoice[_oldBuyer[i]];

            delete invoice[_oldBuyer[i]];
        }
    }

    /**
     * @dev Remove buyers
     * @param _buyer Buyer address
     */
    function removeBuyers(address[] calldata _buyer) external onlyOwner {
        require(buyers.length > 0, "!good");
        for(uint16 i=0; i<_buyer.length; i++){
            if(invoice[_buyer[i]].purchased == 0 || _buyer[i] == address(0)) continue;

            sold -= invoice[_buyer[i]].purchased;

            uint indexToRemove = invoice[_buyer[i]].buyerIndex;
            address addressToRemove = buyers[buyers.length-1];
            
            buyers[indexToRemove] = addressToRemove;
            invoice[addressToRemove].buyerIndex = uint16(indexToRemove);

            buyers.pop();
            delete invoice[_buyer[i]];
        }
    }
    
    /**
     * @dev Update buyers purchase
     * @param _buyer Buyer address
     * @param _newPurchased new purchased
     */
    function updatePurchases(address[] calldata _buyer, uint128[] calldata _newPurchased) external onlyOwner {
        require(_buyer.length == _newPurchased.length && buyers.length > 0, "!good");

        for(uint16 i=0; i<_buyer.length; i++){
            if( invoice[_buyer[i]].purchased == 0 ||
                invoice[_buyer[i]].claimed > 0 ||
                _buyer[i] == address(0) ||
                _newPurchased[i] == 0) continue;
            
            sold = sold - invoice[_buyer[i]].purchased + _newPurchased[i];
            invoice[_buyer[i]].purchased = _newPurchased[i];
        }
    }

    /**
     * @dev Set TGE datetime
     * @param _tgeDatetime TGE datetime in epoch
     */
    function setTgeDatetime(uint32 _tgeDatetime) external onlyOwner {
        _setTgeDatetime(_tgeDatetime);
    }

    /**
     * @dev Set TGE ratio
     * @param _tgeRatio_d2 TGE ratio in percent (2 decimal)
     */
    function setTgeRatio(uint16 _tgeRatio_d2) external onlyOwner {
        _setTgeRatio(_tgeRatio_d2);
    }

    /**
     * @dev Set start & end linear datetime
     * @param _startEndLinearDatetime Start & end Linear datetime in epoch
     */
    function setStartEndLinearDatetime(uint32[2] calldata _startEndLinearDatetime) external onlyOwner {
        _setStartEndLinearDatetime(_startEndLinearDatetime);
    }

    /**
     * @dev Emergency condition to withdraw token
     * @param _target Target address
     */
    function emergencyWithdraw(address _target) external onlyOwner {
        require(_target != address(0), "!good");
        
        TransferHelper.safeTransfer(address(token), _target, IERC20(token).balanceOf(address(this)));
    }

    /**
     * @dev Set token project
     * @param _token Token project address
     */
    function setToken(address _token) external onlyOwner {
        _setToken(_token);
    }
    
    /**
     * @dev Pause vesting activity
     */
    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0) && _newOwner != owner, "!good");
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}