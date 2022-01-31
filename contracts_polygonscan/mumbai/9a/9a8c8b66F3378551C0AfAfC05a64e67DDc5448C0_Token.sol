// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/Owned.sol";
import "../ledger/Ledger.sol";

/**
 * @notice Controller contract for XFUNToken
 */
contract Controller is Owned {
    Ledger public ledger;
    address public token;

    function setToken(address _token) public onlyOwner {
        token = _token;
    }

    function setLedger(address _ledger) public onlyOwner {
        ledger = Ledger(_ledger);
    }

    modifier onlyToken() {
        require(msg.sender == token, "Only token address is allowed.");
        _;
    }

    /**
     * @dev See {Ledger-totalSupply}
     */
    function totalSupply() public view returns (uint256) {
        return ledger.totalSupply();
    }

    /**
     * @dev See {Ledger-balanceOf}
     */
    function balanceOf(address _a) public view onlyToken returns (uint256) {
        return Ledger(ledger).balanceOf(_a);
    }

    /**
     * @dev See {Ledger-allowance}
     */
    function allowance(address _owner, address _spender)
        public
        view
        onlyToken
        returns (uint256)
    {
        return ledger.allowance(_owner, _spender);
    }

    /**
     * @dev See {Ledger-transfer}
     */
    function transfer(
        address _from,
        address _to,
        uint256 _value
    ) public onlyToken returns (bool success) {
        return ledger.transfer(_from, _to, _value);
    }

    /**
     * @dev See {Ledger-transferFrom}
     */
    function transferFrom(
        address _spender,
        address _from,
        address _to,
        uint256 _value
    ) public onlyToken returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    /**
     * @dev See {Ledger-approve}
     */
    function approve(
        address _owner,
        address _spender,
        uint256 _value
    ) public onlyToken returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    /**
     * @dev See {Ledger-increaseApproval}
     */
    function increaseApproval(
        address _owner,
        address _spender,
        uint256 _addedValue
    ) public onlyToken returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    /**
     * @dev See {Ledger-decreaseApproval}
     */
    function decreaseApproval(
        address _owner,
        address _spender,
        uint256 _subtractedValue
    ) public onlyToken returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

    /**
     * @dev See {Ledger-burn}
     */
    function burn(address _owner, uint256 _amount) public onlyToken {
        ledger.burn(_owner, _amount);
    }

    /**
     * @dev See {Ledger-mint}
     */
    function mint(address _account, uint256 _amount) public onlyToken {
        ledger.mint(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IToken {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address owner) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/Owned.sol";

/**
 * @notice Ledger contract for XFUN Token
 */
contract Ledger is Owned {
    address public controller;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply;

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Only controller is allowed");
        _;
    }

    /**
     * @notice Transfer function for XFUN Token
     * @param _from Sender address to Transfer
     * @param _to Recipient address
     * @param _value Transfer Amount
     * @dev Only Controller can call this function
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address _from,
        address _to,
        uint256 _value
    ) public onlyController returns (bool success) {
        require(_to != address(0), "Recipient address should be valid address");
        require(
            balanceOf[_from] >= _value,
            "Sender balance should not be less than transfer amount"
        );

        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        return true;
    }

    /**
     * @notice TransferFrom function for XFUN Token
     * @param _spender Address of Contract or Account which performs transaction
     * @param _from Sender Address
     * @param _to Recipient Address
     * @param _value Amount to Transfer
     * @dev Only Controller can call this function
     *
     * Requirements:
     *
     * - `_from` and `_to` cannot be the zero address.
     * - `_from` must have a balance of at least `_value`.
     * - the caller must have allowance for ``_from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address _spender,
        address _from,
        address _to,
        uint256 _value
    ) public onlyController returns (bool success) {
        require(
            _from != address(0) && _to != address(0),
            "XFUN: transferfrom with unvalid address"
        );

        require(balanceOf[_from] >= _value, "Balance is not sufficient");
        require(
            allowance[_from][_spender] >= _value,
            "Approved amount is not sufficient"
        );

        balanceOf[_to] = balanceOf[_to] + _value;
        balanceOf[_from] = balanceOf[_from] - _value;
        allowance[_from][_spender] = allowance[_from][_spender] - _value;
        return true;
    }

    /**
     * @notice Approve function XFUN Token
     * @param _owner The owner of XFUN Token
     * @param _spender Spender which can be allowed by owner
     * @param _value Approve Amount
     * @dev Only Controller can call this function
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     */
    function approve(
        address _owner,
        address _spender,
        uint256 _value
    ) public onlyController returns (bool success) {
        //require user to set to zero before resetting to nonzero
        require(_owner != address(0), "XFUN: approve from the zero address");
        require(_spender != address(0), "XFUN: approve to the zero address");
        require(
            allowance[_owner][_spender] == 0,
            "Approved amount not be zero"
        );

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval(
        address _owner,
        address _spender,
        uint256 _addedValue
    ) public onlyController returns (bool success) {
        require(_owner != address(0), "XFUN: approve from the zero address");
        require(_spender != address(0), "XFUN: approve to the zero address");

        uint256 oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = oldValue + _addedValue;
        return true;
    }

    function decreaseApproval(
        address _owner,
        address _spender,
        uint256 _subtractedValue
    ) public onlyController returns (bool success) {
        require(_owner != address(0), "XFUN: approve from the zero address");
        require(_spender != address(0), "XFUN: approve to the zero address");

        uint256 oldValue = allowance[_owner][_spender];

        unchecked {
            allowance[_owner][_spender] = oldValue - _subtractedValue;
        }

        return true;
    }

    function mint(address _account, uint256 _amount) public onlyController {
        require(_account != address(0), "XFUN: mint to the zero address");

        balanceOf[_account] += _amount;
        totalSupply += _amount;
    }

    function burn(address _owner, uint256 _amount) public onlyController {
        require(_owner != address(0), "XFUN: burn from the zero address");
        require(
            balanceOf[_owner] >= _amount,
            "XFUN: burn amount exceeds balance"
        );

        balanceOf[_owner] = balanceOf[_owner] - _amount;
        totalSupply = totalSupply - _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Owned {
    constructor() {
        owner = msg.sender;
    }

    address private owner;
    address private newOwner;

    modifier onlyOwner() {        
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../interface/IToken.sol";
import "../controller/Controller.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

/**
 * @notice Token contract for XFUN token
 */
contract Token is BaseRelayRecipient {
    /**
     *  @notice Constant variables for token
     *  @dev name Token Name for XFUN token: `FunFair`
     *  @dev symbol Token Symbol for XFUN token: `XFUN`
     *  @dev decimals Token Decimal for XFUN token: 8
     */

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Mint(
        address indexed minter,
        address indexed contractAddress,
        uint256 amount
    );
    event Burn(
        address indexed minter,
        address indexed contractAddress,
        uint256 amount
    );

    event logTokenTransfer(
        address token,
        address to,
        uint256 amount
    );

    string public name = "Funtoken";
    uint8 public decimals = 8;
    string public symbol = "XFUN";

    /// @notice Controller element
    Controller controller;

    /// @notice owner: Owner Address of XFUN token
    address private owner;
    address private _newOwner;

    /// @notice reference to allowed escrow contracts for transaction and authorization
    mapping(address => bool) allowedEscrows;

    /// @notice reference to enabled escrow contracts to user wallet for escrow functions
    /// @dev user address => escrow contract address
    mapping(address => mapping(address => bool)) userAllowedEscrows;

    /// @notice reference to bridge contracts for minting and burning
    mapping(address => bool) minter;

    string public override versionRecipient = "2.2.0";

    constructor(address forwarder) {
        _setTrustedForwarder(forwarder);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyController() {
        require(
            _msgSender() == address(controller),
            "This user is not registred controller."
        );
        _;
    }

    modifier onlyEscrows() {
        require(
            allowedEscrows[_msgSender()] == true,
            "This user is not escrow account."
        );
        _;
    }

    modifier onlyMinters() {
        require(
            minter[_msgSender()] == true,
            "This user is not registered minter."
        );
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _newOwner = newOwner;
    }

    function acceptOwnership() public {
        if (_msgSender() == _newOwner) {
            owner = _newOwner;
        }
    }

    function claimTokens(address _token, address _to)
        public
        onlyOwner
        returns (bool)
    {
        IToken token = IToken(_token);
        uint256 balance = token.balanceOf(address(this));
        if (token.transfer(_to, balance)) {
            emit logTokenTransfer(_token, _to, balance);
            return true;
        }
        return false;
    }

    /**
     * @notice Check escrow is valid & return if escros is allowed
     * @param _escrow address of escrow contract
     */
    function hasEscrow(address _escrow) internal view returns (bool) {
        require(_escrow != address(0), "Escrow is the zero address");
        return allowedEscrows[_escrow];
    }

    /**
     * @notice Retrurn if the escrow address is enabled by user
     * @param _user User address
     * @param _escrow address of escrow contract
     */
    function hasUserEscrow(address _user, address _escrow)
        internal
        view
        returns (bool)
    {
        require(_user != address(0), "User is the zero address");
        return userAllowedEscrows[_user][_escrow];
    }

    /**
     * @notice Lets owner set the controller contract
     * @param _controller address of controller contract
     */
    function setController(address _controller) external onlyOwner {
        controller = Controller(_controller);
    }

    /**
     * @notice Lets owner add the escrow address
     * @param _escrow address of escrow
     */
    function addEscrow(address _escrow) external onlyOwner {
        require(!hasEscrow(_escrow), "This escrow is already allowed");
        allowedEscrows[_escrow] = true;
    }

    /**
     * @notice Lets owner remove the escrow address
     * @param _escrow address of escrow
     */
    function removeEscrow(address _escrow) external onlyOwner {
        require(hasEscrow(_escrow), "This escrow is not allowed");
        allowedEscrows[_escrow] = false;
    }

    /**
     * @notice Lets user enable the escrow address
     * @param _escrow address of escrow
     */
    function enableEscrow(address _escrow) external {
        require(hasEscrow(_escrow), "This escrow is not allowed");
        require(
            !hasUserEscrow(_msgSender(), _escrow),
            "This escrow is already enabled by user"
        );
        userAllowedEscrows[_msgSender()][_escrow] = true;
    }

    /**
     * @notice Lets user disable the escrow address
     * @param _escrow address of escrow
     */
    function disableEscrow(address _escrow) external {
        require(hasEscrow(_escrow), "This escrow is not allowed");
        require(
            hasUserEscrow(_msgSender(), _escrow),
            "This escrow is not enabled by user"
        );
        userAllowedEscrows[_msgSender()][_escrow] = false;
    }

    /**
     * @notice Lets owner register the bridge contract
     * @param _minter address of Minter
     * @dev Minter can be bridge contract and owner or the others
     */
    function registerMinter(address _minter) external onlyOwner {
        require(minter[_minter] != true, "This minter is already registered.");
        minter[_minter] = true;
    }

    /**
     * @notice Lets owner remove the bridge contract
     * @param _minter address of Minter
     * @dev Minter can be bridge contract and owner or the others
     */
    function removeMinter(address _minter) external onlyOwner {
        require(minter[_minter] == true, "This minter is not registered");
        minter[_minter] = false;
    }

    /**
     * @dev See {Controller-balanceOf}.
     */
    function balanceOf(address _account) public view returns (uint256) {
        return controller.balanceOf(_account);
    }

    /**
     * @dev See {Controller-balanceOf}.
     */
    function totalSupply() public view returns (uint256) {
        return controller.totalSupply();
    }

    /**
     * @notice Check if account is minter or not
     * @param _account address which is willing to be checked
     */
    function isMinter(address _account) public view returns (bool) {
        return minter[_account];
    }

    /**
     * @dev See {Controller-allowance}.
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return controller.allowance(_owner, _spender);
    }

    /**
     * @dev See {Controller-transfer}.
     */
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(success = controller.transfer(_msgSender(), _to, _value));
        emit Transfer(_msgSender(), _to, _value);
    }

    /**
     * @dev See {Controller-transferFrom}.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            success = controller.transferFrom(_msgSender(), _from, _to, _value)
        );
        emit Transfer(_from, _to, _value);
    }

    /**
     * @dev See {Controller-approve}.
     */
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        //promote safe user behavior
        require(
            controller.allowance(_msgSender(), _spender) == 0,
            "Allowance not be zero."
        );

        success = controller.approve(_msgSender(), _spender, _value);
        if (success) {
            emit Approval(_msgSender(), _spender, _value);
        }
    }

    /**
     * @dev See {Controller-increaseApproval}.
     */
    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool success)
    {
        success = controller.increaseApproval(
            _msgSender(),
            _spender,
            _addedValue
        );
        if (success) {
            uint256 newval = controller.allowance(_msgSender(), _spender);
            emit Approval(_msgSender(), _spender, newval);
        }
    }

    /**
     * @dev See {Controller-decreaseApproval}.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool success)
    {
        success = controller.decreaseApproval(
            _msgSender(),
            _spender,
            _subtractedValue
        );
        if (success) {
            uint256 newval = controller.allowance(_msgSender(), _spender);
            emit Approval(_msgSender(), _spender, newval);
        }
    }

    /**
     * @notice Let controller emits TransferEvent after transfer execution in controller
     * @param _from Sender address to transfer
     * @param _to Receiver address to transfer
     * @param _value Transfer Amount
     * @dev This function is allowed for only Controller
     */
    function controllerTransfer(
        address _from,
        address _to,
        uint256 _value
    ) external onlyController {
        emit Transfer(_from, _to, _value);
    }

    /**
     * @notice Let controller emits Aprrove after Approve execution in controller
     * @param _owner Owner address for Approve
     * @param _spender Spender address for Approve
     * @param _value Approve Amount
     * @dev This function is allowed for only Controller
     */
    function controllerApprove(
        address _owner,
        address _spender,
        uint256 _value
    ) external onlyController {
        emit Approval(_owner, _spender, _value);
    }

    /**
     * @notice Lets escrow store in Escrow
     * @param _from Sender address for Escrow
     * @param _value Amount to store in Escrow
     */
    function escrowFrom(address _from, uint256 _value) external onlyEscrows {
        require(
            hasUserEscrow(_from, _msgSender()),
            "This escrow is not enabled by user"
        );
        require(_from != address(0) && _value > 0);
        require(controller.transfer(_from, _msgSender(), _value));
        emit Transfer(_from, _msgSender(), _value);
    }

    /**
     * @notice Lets escrow return to receiver
     * @param _to Receiver address to get the value from Escrow
     * @param _value Return Amount
     * @param _fee Escrow Fee Amount
     */
    function escrowReturn(
        address _to,
        uint256 _value,
        uint256 _fee
    ) external onlyEscrows {
        require(_to != address(0) && _value > 0);
        if (_fee > 0) {
            //Decrease the total supply and escrow balance when _fee is bigger than 0
            require(
                _fee < controller.totalSupply() &&
                    _fee < controller.balanceOf(_msgSender())
            );
            controller.burn(_msgSender(), _fee);
        }
        require(controller.transfer(_msgSender(), _to, _value));
        emit Transfer(_msgSender(), _to, _value);
    }

    /**
     * @notice Mint Function
     * @param _account Minting Address
     * @param _amount Minting Amount
     * @dev See {Controller - mint}
     */
    function mint(address _account, uint256 _amount) public onlyMinters {
        controller.mint(_account, _amount);
        emit Mint(_msgSender(), address(this), _amount);
        emit Transfer(address(this), _account, _amount);
    }

    /**
     * @notice Burn Function
     * @param _amount Burn Amount
     * @dev See {Controller-burn}.
     */
    function burn(
        address _account,
        uint256 _amount,
        uint256 _fee
    ) public onlyMinters {
        controller.burn(_account, _amount + _fee);
        emit Transfer(_account, address(this), _amount);
        emit Burn(_msgSender(), address(this), _amount);
    }
}