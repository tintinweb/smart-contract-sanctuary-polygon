// SPDX-License-Identifier: None

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./IMPAFactory.sol";
import "./Strings.sol";

contract MPA {

    string name;
    string description;

    address payable private factory;
    address private creator;
    uint private fee;

    struct User {
        address user;
        uint shares;
    }

    bool private hidden;
    bool private frozen;
    bool private locked;

    User[] shareholders;

    mapping(address => uint) withdrawn;
    mapping(address => uint) private totalTokenWithdrawn;
    mapping(address => mapping(address => uint)) tokenWithdrawn;
    uint private totalRevenue;
    uint private totalShares;

    error AccessDenied();
    error TransferFailed();

    modifier onlyCreator {
        require(msg.sender == creator, "Error: 1011");
        _;
    }

    function adminAccess(address _addr) private view returns (bool) {
        if(IMPAFactory(factory).isManagement(_addr)) return true;
        return false;
    }

    constructor(
        string memory _name,
        string memory _desc,
        address[] memory _shareholders,
        uint[] memory _shares,
        uint _totalShares,
        uint _fee,
        address _creator,
        address _factory,
        bool _private
    ) {
        name = _name;
        description = _desc;
        totalShares = _totalShares;
        fee = _fee;
        creator = _creator;
        factory = payable(_factory);
        hidden = _private;

        frozen = false;
        locked = false;

        for(uint i = 0; i < _shareholders.length; i++) {
            shareholders.push(User(_shareholders[i], _shares[i]));
        }
    }

    fallback() external payable {
        require(!frozen && !locked, "Error: 1015");
        uint transactionFee = ( msg.value / 100000000 ) * fee;
        totalRevenue = totalRevenue + msg.value - transactionFee;
        transfer(factory, transactionFee);
    }

    function freeze(bool _state) external {
        require(adminAccess(msg.sender), "Denied.");
        frozen = _state;
    }

    function lock(bool _state) onlyCreator external {
        locked = _state;
    }

    function getData(address _addr) external view returns (string[] memory) {
        string[] memory data = new string[](10);
        data[0] = name;
        data[1] = description;
        data[2] = Strings.toHexString(creator);
        data[3] = Strings.toString(getShares(_addr));
        data[4] = Strings.toString(totalShares);
        data[5] = Strings.toString(getBalance(_addr));
        data[6] = Strings.toString(address(this).balance);
        if(hidden) { data[7] = "true"; } else { data[7] = "false"; }
        if(locked) { data[8] = "true"; } else { data[8] = "false"; }
        if(frozen) { data[9] = "true"; } else { data[9] = "false"; }
        return data;
    }

    function getShareholders() external view returns (User[] memory) {
        if(!hidden) return shareholders;
        revert AccessDenied();
    }

    function isShareholder(address _addr) private view returns (bool) {
        for(uint i = 0; i < shareholders.length; i++) {
            if(shareholders[i].user == _addr) { return true; }
        }
        return false;
    }

    function getShares(address _addr) private view returns (uint) {
        for(uint i = 0; i < shareholders.length; i++) {
            if(shareholders[i].user == _addr) return shareholders[i].shares;
        }
        return 0;
    }

    function hideShareholders(bool _state) external {
        require(msg.sender == creator || adminAccess(msg.sender), "Denied.");
        hidden = _state;
    }

    function withdraw(uint _amount, address _token, bool _native) external {
        
        require(!frozen, "Withdrawls have been frozen.");
        require(isShareholder(msg.sender), "Denied.");

        if(!_native) {
            require(_amount <= getTokenBalance(msg.sender, _token), "Insufficient Funds.");
            tokenWithdrawn[_token][msg.sender] += _amount;
            totalTokenWithdrawn[_token] += _amount;
            IERC20(_token).transfer(msg.sender, _amount);
        } else {
            require(_amount <= getBalance(msg.sender), "Insufficient Funds.");
            withdrawn[msg.sender] += _amount;
            transfer(msg.sender, _amount);
        }
    }

    function globalPayout(address _token, bool _native) external {

        require(!frozen, "Withdrawls have been frozen.");
        require(msg.sender == creator || adminAccess(msg.sender), "Denied.");

        for(uint i = 0; i < shareholders.length; i++) {
            address account = shareholders[i].user;
            if(_native) {
                uint balance = getBalance(account);
                withdrawn[account] += balance;
                transfer(account, balance);
            } else {
                uint tokenBalance = getTokenBalance(account, _token);
                tokenWithdrawn[_token][account] += tokenBalance;
                totalTokenWithdrawn[_token] += tokenBalance;
                IERC20(_token).transfer(account, tokenBalance);
            }
        }
    }

    function getBalance(address _addr) private view returns (uint) {
        return ( totalRevenue * getShares(_addr) / totalShares - withdrawn[_addr] );
    }

    function getTokenBalance(address _addr, address _token) public view returns (uint) {
        uint totalTokenReceived = IERC20(_token).balanceOf(address(this)) + totalTokenWithdrawn[_token];
        return ( totalTokenReceived * getShares(_addr) / totalShares - tokenWithdrawn[_token][_addr] );
    }

    function getTotalTokenBalance(address _token) external view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    // https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    function transfer(address _to, uint _amount) private {
        bool callStatus;
        assembly {
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        if(!callStatus) revert TransferFailed();
    }

}