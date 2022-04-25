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

import "./IGovCreator.sol";
import "./KomGov.sol";

contract GovCreator is IGovCreator{
    address public override immutable komv;

    address[] public override allRegistrations; // all registrations created
    
    address public override owner = msg.sender;

    modifier onlyOwner{
        require(owner == msg.sender, "!owner");
        _;
    }
    
    constructor(address _komv){
        require(_komv != address(0), "bad");
        
        komv = _komv;
    }
    
    /**
     * @dev Get total number of registrations created
     */
    function allRegistrationsLength() external override view returns (uint) {
        return allRegistrations.length;
    }
    
    /**
     * @dev Create new registration
     * @param _name Project name
     * @param _version Project registration version
     * @param _message Project registration message
     */
    function createRegistration(
        string calldata _name,
        string calldata _version,
        string calldata _message,
        uint128 _start,
        uint128 _end
    ) external override onlyOwner returns(address registration){
        require(bytes(_message).length != 0, "bad");
        
        registration = address(new KomGov());

        allRegistrations.push(registration);
        
        KomGov(registration).initialize(_name, _version, _message, _start, _end);
        
        emit RegistrationCreated(registration, allRegistrations.length-1);
    }
    
    /**
     * @dev Transfer ownership to new owner
     * @param _newOwner New owner
     */
    function transferOwnership(address _newOwner) external override onlyOwner{
        require(_newOwner != address(0), "bad");
        owner = _newOwner;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IGovCreator{
    event RegistrationCreated(address indexed registration, uint index);
    
    function owner() external  view returns (address);
    
    function komv() external  view returns (address);
    
    function allRegistrationsLength() external view returns(uint);
    
    function allRegistrations(uint) external view returns(address);

    function createRegistration(string calldata, string calldata, string calldata, uint128, uint128) external returns (address);
    
    function transferOwnership(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasProject{
    function migrateCandidates(address[] calldata) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IGovCreator.sol";
import "./IKommunitasProject.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KomGov{
    bytes32 constant FORM_TYPEHASH = keccak256(
        "Form(address from,string content)"
    );

    address public immutable komv;
    address public immutable gov = msg.sender;

    bool private initialized;
    address public owner = tx.origin;

    bytes32 public DOMAIN_SEPARATOR;

    uint128 public start;
    uint128 public end;

    string public name;
    string public version;
    string public message;

    address[] public candidates;
    
    mapping(address => bool) private registered;

    struct Form {
        address from;
        string content;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }

    constructor(){
        komv = IGovCreator(gov).komv();
    }

    function initialize(
        string calldata _name,
        string calldata _version,
        string calldata _message,
        uint128 _start,
        uint128 _end
    ) external {
        require(!initialized, "initialized");
        require(msg.sender == gov, "!gov");

        start = _start;
        end = _end;
        message = _message;

        _createDomain(_name, _version);

        initialized = true;
    }

    function getCandidateLength() external view returns (uint) {
        return candidates.length;
    }

    function _createDomain(string calldata _name, string calldata _version) private {
        require(bytes(_name).length != 0 && bytes(_version).length != 0, "bad");

        name = _name;
        version = _version;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
            0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
            keccak256(bytes(_name)),
            keccak256(bytes(_version)),
            chainId,
            address(this)
        ));
    }

    function hash(Form memory form) private pure returns (bytes32) {
        return keccak256(abi.encode(
            FORM_TYPEHASH,
            form.from,
            keccak256(bytes(form.content))
        ));
    }

    function verify(address _from, bytes memory _signature) public view returns (bool) { // TESTING !
    // function verify(address _from, string memory _content, _signature) private view returns(bool) {
        if(_signature.length != 65) return false;

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        Form memory form = Form({
            from: _from,
            content: message
        });

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(form)
        ));

        return ecrecover(digest, v, r, s) == _from;
    }

    function migrate(
        address _saleTarget,
        address[] calldata _from,
        bytes[] calldata _signature,
        uint128[] calldata _votedAt
    ) external onlyOwner {
        require(_saleTarget != address(0) && _from.length == _signature.length && block.timestamp > end, "bad");

        for(uint i=0; i<_from.length; i++){
            if(
                registered[_from[i]] &&
                !(
                    verify(_from[i], _signature[i]) &&
                    IERC20(komv).balanceOf(_from[i]) > 0 &&
                    _votedAt[i] >= start &&
                    _votedAt[i] <= end
                )
            ) continue;

            registered[_from[i]] = true;
            candidates.push(_from[i]);
        }

        require(IKommunitasProject(_saleTarget).migrateCandidates(candidates), "fail");
    }

    function updateDomain(string calldata _name, string calldata _version) external onlyOwner {
        require(block.timestamp < start, "bad");
        _createDomain(_name, _version);
    }

    function updateMessage(string calldata _message) external onlyOwner {
        require(bytes(_message).length != 0 && block.timestamp < start, "bad");
        message = _message;
    }

    function updateStart(uint128 _start) external onlyOwner {
        require(_start != 0 && block.timestamp < start, "bad");
        start = _start;
    }

    function updateEnd(uint128 _end) external onlyOwner {
        require(_end != 0 && block.timestamp < start, "bad");
        end = _end;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "bad");
        owner = _newOwner;
    }
}