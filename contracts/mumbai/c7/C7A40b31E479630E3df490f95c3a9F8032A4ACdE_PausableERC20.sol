pragma solidity ^0.8.0;
import "./ERC20.sol";

contract PausableERC20 is ERC20{
    address public owner;
    bool public _paused;
    event Paused(address account);
    event Unpaused(address account);

    constructor(string memory name_, string memory symbol_,uint256 totalSupply_,uint8 decimals_) ERC20( name_,  symbol_, totalSupply_, decimals_){
        owner=msg.sender;
        _paused = false;

    }
     


    /**
     * @dev Initializes the contract in unpaused state.
     */


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
     //P=Pausable: paused

     //NP=Pausable: not paused
    function _requireNotPaused() internal view virtual {
        require(!paused(), "P");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "NP");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
    //ETTWP=ERC20Pausable: token transfer while paused
   function _beforeTokenTransfer (address  from, address  to, uint256  amount) internal  override view {
       require(!paused(), "ETTWP");

   }
   
    
}