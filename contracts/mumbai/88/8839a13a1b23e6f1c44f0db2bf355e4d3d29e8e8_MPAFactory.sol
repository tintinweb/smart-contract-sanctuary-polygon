// SPDX-License-Identifier: None

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./MPA.sol";

contract MPAFactory {

    event newMPA(address indexed by, address indexed mpa);

    address payable private owner;
    address private manager;

    uint private creationFee;
    uint private transactionFee;

    struct User {
        address user;
        address[] owned;
        address[] participating;
    }

    mapping(address => User) private users;

    fallback() external payable {}

    constructor() {
        owner = payable(msg.sender);
        manager = msg.sender;
        creationFee = 0; // Wei
        transactionFee = 4000000; // Fraction of 100,000,000
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Denied.");
        _;
    }

    function isManagement(address _addr) public view returns (bool) {
        if(_addr == owner || _addr == manager) { return true; }
        return false;
    }

    function create(
        string memory _name,
        string memory _desc,
        address[] memory _shareholders,
        uint[] memory _shares,
        bool _private
    ) external payable {

        require(msg.value >= creationFee, "Error: 1002");
        require(bytes(_name).length <= 25 && bytes(_desc).length <= 150, "Error: 1003");
        require(_shareholders.length == _shares.length, "Error: 1004");

        uint totalShares;
        for(uint16 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
        }

        // Max 1 Trillion
        require(totalShares <= 1000000000000, 'Error: 1005');

        MPA mpa = new MPA(
            _name,
            _desc,
            _shareholders,
            _shares,
            totalShares,
            transactionFee,
            msg.sender,
            address(this),
            _private
        );

        users[msg.sender].owned.push(address(mpa));
        for(uint i = 0; i < _shareholders.length; i++) {
            users[_shareholders[i]].participating.push(address(mpa));
        }

        emit newMPA(msg.sender, address(mpa));
    }

    function getOwnedMPAs(address _user) external view returns (address[] memory) {
        return users[_user].owned;
    }

    function getParticipatingMPAs(address _user) external view returns (address[] memory) {
        return users[_user].participating;
    }

    function changeOwner(address _newOwner) onlyOwner external {
        owner = payable(_newOwner);
    }

    function changeManager(address _newManager) onlyOwner external {
        manager = _newManager;
    }

    function changeCreationFee(uint _fee) onlyOwner external {
        creationFee = _fee;
    }

    function changeTransactionFee(uint _fee) onlyOwner external {
        transactionFee = _fee;
    }

    function releaseFunds(address[] calldata _tokens) onlyOwner external {
        transfer(owner, address(this).balance);
        for(uint i = 0; i < _tokens.length; i++) {
            uint balance = IERC20(_tokens[i]).balanceOf(address(this));
            IERC20(_tokens[i]).transfer(owner, balance);
        }
    }

    // https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();
    function transfer(address to, uint amount) private {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if(!callStatus) revert TransferFailed();
    }

}