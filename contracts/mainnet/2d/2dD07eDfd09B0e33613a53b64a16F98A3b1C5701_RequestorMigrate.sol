/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGRefReward {
    function updateVIPBlockWithPermit(address account,uint256 timer) external returns (bool);
    function increaseRecordData(address account,string memory dataSlot,uint256 index,uint256 amount) external returns (bool);
}

interface IAllSale {
    function totalPaid() external view returns (uint256);
    function totalStakedPLG() external view returns (uint256);
    function totalRewardDeposit() external view returns (uint256);
    function user(address account) external view returns (uint256[] memory);
    function updateAppStateWithPermit(uint256[] memory data) external returns (bool);
    function updateUserWithPermit(address account, uint256[] memory data) external returns (bool);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint256);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }

    modifier forRole(string memory str) {
        require(checkpermit(msg.sender,str),"Permit Revert!");
        _;
    }
}

contract RequestorMigrate is permission {
    
    address public owner;

    address public old_plg_token = 0x919A5712057173C7334cc60E7657791fF9ca6E8d;
    address public old_plg_refreward = 0x5EEddE12d4F65af99a29c27Dcbb9389732ddAC4a;

    IPLGFactory factory;

    uint256[] pendingId;
    uint256[] successId;
    
    uint256 public requested_id;
    mapping(address => uint256) public requestStatus;
    mapping(uint256 => address) public requestOWNER;
    mapping(uint256 => mapping(uint256 => uint256)) public requestDATA;
    
    constructor(address _factory) {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        factory = IPLGFactory(_factory);
    }

    function getPendingId() public view returns (uint256[] memory) { return pendingId; }
    function getSuccessId() public view returns (uint256[] memory) { return successId; }

    function requestingMigrate(uint256[] memory data) public returns (bool) {
        require(requestStatus[msg.sender]!=1 && requestStatus[msg.sender]!=2);
        _requestingMigrate(msg.sender,data);
        return true;
    }

    function requestingMigrateWithPermit(address account,uint256[] memory data) public forRole("permit") returns (bool) {
        _requestingMigrate(account,data);
        return true;
    }

    function approveId(uint256 id) public forRole("permit") returns (bool) {
        address txowner = requestOWNER[id];
        IERC20(old_plg_token).transferFrom(txowner,address(this),requestDATA[id][0]);
        IERC20(factory.getAddr("plg_token")).transfer(txowner,requestDATA[id][0]);
        IPLGRefReward(factory.getAddr("plg_refreward")).updateVIPBlockWithPermit(txowner,requestDATA[id][1]);
        uint256[] memory getdata = IAllSale(factory.getAddr("plg_allsale")).user(txowner);
        uint256[] memory inputdata = new uint256[](2);
        inputdata[0] = getdata[0] + requestDATA[id][2];
        inputdata[1] = getdata[1] + requestDATA[id][3];
        IAllSale(factory.getAddr("plg_allsale")).updateUserWithPermit(txowner,inputdata);
        uint256 totalPaid = IAllSale(factory.getAddr("plg_allsale")).totalPaid();
        uint256 totalStakedPLG = IAllSale(factory.getAddr("plg_allsale")).totalStakedPLG();
        uint256 totalRewardDeposit = IAllSale(factory.getAddr("plg_allsale")).totalRewardDeposit();
        uint256[] memory appdata = new uint256[](3);
        appdata[0] = totalPaid + requestDATA[id][3];
        appdata[1] = totalStakedPLG + requestDATA[id][0];
        appdata[2] = totalRewardDeposit;
        IAllSale(factory.getAddr("plg_allsale")).updateAppStateWithPermit(appdata);
        requestStatus[txowner] = 2;
        successId.push(id);
        return true;
    }

    function rejectId(uint256 id) public forRole("permit") returns (bool) {
        address txowner = requestOWNER[id];
        requestStatus[txowner] = 3;
        return true;
    }

    function _requestingMigrate(address account,uint256[] memory data) internal {
        requested_id += 1;
        requestOWNER[requested_id] = account;
        pendingId.push(requested_id);
        for(uint256 i=0; i<data.length; i++){
            requestDATA[requested_id][i] = data[i];
        }
        requestStatus[account] = 1;
    }

    function getDataFromId(uint256 id) public view returns (address,uint256[] memory,uint256) {
        uint256[] memory data = new uint256[](4);
        data[0] = requestDATA[id][0];        //[0] PLG Amount Holding
        data[1] = requestDATA[id][1];        //[1] UnlockVIPBlock
        data[2] = requestDATA[id][2];        //[2] Locked PLG
        data[3] = requestDATA[id][3];        //[3] Claimed PLG
        return (requestOWNER[id],data,requestStatus[requestOWNER[id]]);
    }

    function factoryAddressSetting(address _factory) public forRole("owner") returns (bool) {
        factory = IPLGFactory(_factory);
        return true;
    }

    function purgeToken(address token) public forRole("owner") returns (bool) {
      uint256 amount = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(msg.sender,amount);
      return true;
    }

    function purgeETH() public forRole("owner") returns (bool) {
      (bool success,) = msg.sender.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
      return true;
    }

    function grantRole(address adr,string memory role) public forRole("owner") returns (bool) {
        newpermit(adr,role);
        return true;
    }

    function revokeRole(address adr,string memory role) public forRole("owner") returns (bool) {
        clearpermit(adr,role);
        return true;
    }

    function transferOwnership(address adr) public forRole("owner") returns (bool) {
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        owner = adr;
        return true;
    }

    receive() external payable {}
}