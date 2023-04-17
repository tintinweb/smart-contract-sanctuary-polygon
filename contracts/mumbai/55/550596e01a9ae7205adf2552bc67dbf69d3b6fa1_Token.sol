// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./Main.sol";

//user can transfer

contract Token is ERC20PermitUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    address public main;
    bool public isTransferPaused;

    modifier onlyMain() {
        require(msg.sender == main, "Not main");
        _;
    }

    modifier notPaused() {
        require(!isTransferPaused, "On pause");
        _;
    }

    event UnsufficientBalance(address indexed player);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("name", "FTV");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _mint(msg.sender, 10 ** 18);
        isTransferPaused = true;
    }

    //TODO Change
    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

    function _sudoTranfer(address[] memory players, uint amount) public onlyMain returns (bool) {
        uint balanceBefore = balanceOf(main);
        for (uint256 i = 0; i < players.length; ++i) {
            address player = players[i];
            /// @dev To prevent DOS attack
            /// @dev Balances was checked before tx, so revert possible only when DOS/Frontrunning
            if (balanceOf(player) < amount) {
                emit UnsufficientBalance(player);
                require(false, "UnsufficientBalance");
            }
            // msg.sender = main
            _transfer(player, main, amount);
        }
        uint balanceAfter = balanceOf(main);
        require(balanceAfter >= balanceBefore + (amount * players.length), "Wrong balance after");
        return true;
    }

    /// @param winner winner's account
    /// @param amount amount including fee
    function _awardWinner(address winner, uint amount) public onlyMain returns (bool) {
        _transfer(main, winner, amount);
        return true;
    }

    function setMain(address _newMain) public onlyOwner {
        require(_newMain != address(0));
        main = _newMain;
    }

    /// @dev TODO make custom transfer
    function transfer(address to, uint256 amount) public override notPaused returns (bool) {
        address _owner = _msgSender();
        _transfer(_owner, to, amount);
        return true;
    }

    /// @dev TODO make custom transfer
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override notPaused returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[49] private __gap;
}