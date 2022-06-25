// SPDX-License-Identifier: MIT
/*
Badass Bunny Coin Smart Contract by Cahit Karahan
                                                                                
                                                                                
                            ..  .......    ..     ..                            
                 ........ .. .: :  ..  .. :  . ::    ........                   
                :  ..  ::-.   .-=  :++. :-    :-:  ..::.  ...:                  
        ...:::::=      .::  .  :+  .-:  -.     =-...  .:.. .:=--:::::::.        
      ...:---:::=  ... ..   ..  .    ..=. ....  .     .. ..  .=-----:.          
   .=#########*==......::---===-============+====-:-==-:...:::======---:::.     
   .#####***#####+=====---------==+=---------==-=##=-==++===+-#############+.   
   .####*:.:.####*:=+=::-:=.####**###=:=+=-===-:=**=---=***+-.-====++*#####+:   
   .+####---+####+:##*:= *#:*##+---##*:###**###+:.--.+##+-=##*:. .::+####*-.    
   .=############==##+:..##-=##+:-.##+-##*--.### ##=:##*+++###-:.:+####+-.      
    :####*+++==*#-+##+..=##+.##*.=.*#-+##+:::### *#*.*#*=---=-::=####*=.        
     ####+:....-#*:*##**##*=.=*=---:=:*##=-:+##+.+##=:+*####*-=####*=:          
   . *###*====+####---=+=-.      .:::::---:-:++-:=##+: .::-:=*####+::.. .       
    .+###########*+-               .::::::::.    .+*-.    .+############**=.    
     .=++++====-:.                    .::.                 .-+++******####+:    
                                                                  . ....::.     
                                                                                
                                                                                
*/
pragma solidity ^0.8.0.0;

import "./AccessControl.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";

contract BadassBunnyCoin is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address public ERC721Contract;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _owner,
        address _ERC721Contract
    ) ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);

        _setupRole(MINTER_ROLE, _owner);
        _setupRole(PAUSER_ROLE, _owner);

        _mint(_owner, _initialSupply);

        ERC721Contract = _ERC721Contract;
    }

    function _onlyERC721Contract() private view {
        require(_msgSender() == ERC721Contract, "Only ERC721 manager contract can call this function!");
    }

    modifier onlyERC721Contract() {
        _onlyERC721Contract();
        _;
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "You have to have the minter role to mint!");
        _mint(to, amount);
    }

    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "You have to have the pauser role to pause!");
        _pause();
    }

    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "You have to have the pauser role to unpause!");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function contractMint(address _to, uint256 _amount) external onlyERC721Contract returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function contractBurn(address _from, uint256 _amount) external onlyERC721Contract returns (bool) {
        _burn(_from, _amount);
        return true;
    }

    function contractPause() external onlyERC721Contract returns (bool) {
        _pause();
        return true;
    }

    function contractUnpause() external onlyERC721Contract returns (bool) {
        _unpause();
        return true;
    }

    function contractTransfer(address _from, address _to, uint256 _amount) external onlyERC721Contract returns (bool) {
        _transfer(_from, _to, _amount);
        return true;
    }

    function contractApprove(address _owner, address _spender, uint256 _amount) external onlyERC721Contract returns (bool) {
        _approve(_owner, _spender, _amount);
        return true;
    }
}