/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement( address newOwner_ ) external;

    function pullManagement() external;
     
    }


contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface IBTCpx {
    function getReward() external;
    function earned(address account) external view returns (uint256);
    function stake( uint _amount, address _recipient ) external returns ( bool );
}

interface IStakingHelper {
    function stake( uint _amount, address _recipient ) external returns ( bool );
  
}


contract iBTCpxHelper is Ownable {

    address public iBTCpxAddress;
    address public Staking;
    

    function claimAndStake() external {
        uint256 reward = IBTCpx(iBTCpxAddress).earned(msg.sender);
        IBTCpx(iBTCpxAddress).getReward();
        IBTCpx(iBTCpxAddress).stake(reward, msg.sender);
    }

    function setIBTCpxContract( address _iBTCpxAddress ) external onlyPolicy() {
        require( _iBTCpxAddress != address(0) );
        iBTCpxAddress = _iBTCpxAddress;
    }
}