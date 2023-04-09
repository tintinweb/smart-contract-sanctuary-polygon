/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}







interface ITokenX is IERC20 {
    function getLockedAddressesLength() external view returns (uint256);
    function lockedAddresses(uint256 index) external view returns (address);
    function getLockedTokens(address account) external view returns (uint256);
    function unlock(address account, uint256 amount) external;
}

contract Presale{
    ITokenX public tokenX;
    address public adminWallet; // Nueva variable para almacenar la dirección de la wallet adicional
    address public owner;
    uint256 public rate;
    uint256 public minInvestment;
    uint256 public maxTotalInvestment;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalRaised;
    bool public presaleEnded;
    uint256 public startTime;
    uint256 public duration;
    uint256 public whitelistedCount;
    mapping(address => uint256) public investedAmount;
    mapping(address => bool) public whitelist;

    // Eventos
    event TokenPurchase(address indexed buyer, uint256 amount);
    event TokensUnlocked(address indexed buyer, uint256 amount);

    constructor(
        address _tokenXAddress,
        uint256 _rate,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _durationInDays,
        address _adminWallet // Nuevo parámetro para recibir la dirección de la wallet adicional
   
    ) {
        require(_softCap <= _hardCap, "El soft cap debe ser menor o igual que el hard cap");

        tokenX = ITokenX(_tokenXAddress); // Dirección del token X en el contrato ERC20
        rate = _rate; // Tasa de cambio de MATIC a token X (cantidad de tokens X por 1 MATIC)
        owner = msg.sender; // Dirección del propietario del contrato (creador de la preventa)
        adminWallet = _adminWallet; // Almacenar la dirección de la wallet adicional
        minInvestment = _minInvestment; // Monto mínimo de MATIC que un inversor puede invertir en la preventa
        maxTotalInvestment = _maxInvestment; // Monto máximo de MATIC que un inversor puede invertir en total durante la preventa
        softCap = _softCap; // Monto mínimo de MATIC a recaudar para que la preventa sea exitosa; si no se alcanza, los inversores pueden retirar su inversión
        hardCap = _hardCap; // Monto máximo de MATIC a recaudar en la preventa; una vez alcanzado, no se pueden realizar más compras y la preventa finaliza
        startTime = block.timestamp; // Hora de inicio de la preventa, establecida en el momento de la creación del contrato
        duration = _durationInDays * 1 days; // Duración de la preventa en días; se convierte en segundos para facilitar el cálculo del tiempo
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == adminWallet, unicode"Solo el propietario puede realizar esta acción");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], unicode"No estás en la lista blanca");
        _;
    }

// Permite a los inversores en la lista blanca comprar tokens X utilizando MATIC durante la preventa.
 function buyTokens() external payable onlyWhitelisted {
    require(block.timestamp <= startTime + duration, unicode"La preventa ha finalizado");

    uint256 maticAmount = msg.value;

    require(maticAmount >= minInvestment, unicode"La inversión no cumple con el límite mínimo establecido");

    uint256 totalInvestment = investedAmount[msg.sender] + maticAmount;
    require(totalInvestment <= maxTotalInvestment, unicode"La inversión total no cumple con el límite máximo establecido");

    uint256 tokensToBuy = maticAmount * rate / 1 ether;
    require(tokenX.balanceOf(address(this)) >= tokensToBuy, unicode"No hay suficientes tokens X disponibles");

    investedAmount[msg.sender] = totalInvestment; // Almacena la cantidad total invertida por la dirección
    totalRaised += maticAmount; // Actualiza la cantidad total recaudada

    // Emitir el evento TokenPurchase
    emit TokenPurchase(msg.sender, tokensToBuy);
}


// Finaliza la preventa y transfiere los MATIC recaudados al propietario del contrato si se alcanza el soft cap.
function endPresale() external onlyOwner {
    require(!presaleEnded, unicode"La preventa ya ha finalizado");
    presaleEnded = true;

    if (totalRaised >= softCap && block.timestamp > startTime + duration) {
        // Transfiere los fondos de MATIC al propietario del contrato
        payable(adminWallet).transfer(address(this).balance);
    }
}

   // Permite a los inversores solicitar un reembolso si la preventa no alcanza el soft cap.
    function refundInvestment() external {
        require(presaleEnded, unicode"La preventa aún no ha finalizado");
        require(totalRaised < softCap, unicode"No se permite el reembolso, se alcanzó el soft cap");

        uint256 maticToRefund = investedAmount[msg.sender];
        require(maticToRefund > 0, unicode"No tienes fondos para reembolsar");

        investedAmount[msg.sender] = 0;
        payable(msg.sender).transfer(maticToRefund);
    }


 // Permite a los inversores retirar los tokens X comprados una vez que la preventa haya finalizado y se haya alcanzado el soft cap.
      function withdrawTokens() external {
        //require(presaleEnded, unicode"La preventa aún no ha finalizado");
       // require(totalRaised >= softCap, unicode"El soft cap no fue alcanzado, no se pueden retirar los tokens");

        //uint256 tokensToWithdraw = investedAmount[msg.sender] * rate;
        uint256 tokensToWithdraw = (investedAmount[msg.sender] * rate) / (10 ** 9);

        require(tokensToWithdraw > 0, unicode"No tienes tokens para retirar");

        investedAmount[msg.sender] = 0;
        tokenX.transfer(msg.sender, tokensToWithdraw);

        emit TokensUnlocked(msg.sender, tokensToWithdraw);
    }


  // Permite al propietario del contrato retirar los tokens X no vendidos una vez finalizada la preventa.
        function withdrawUnsoldTokens() external onlyOwner {
            require(presaleEnded, unicode"La preventa aún no ha finalizado");
            uint256 unsoldTokens = tokenX.balanceOf(address(this));
            tokenX.transfer(adminWallet, unsoldTokens);
        }


// Agrega múltiples direcciones a la lista blanca, permitiéndoles participar en la preventa.
    function addMultipleToWhitelist(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            require(!whitelist[users[i]], unicode"Un usuario ya está en la lista blanca");
            whitelist[users[i]] = true;
            whitelistedCount++;//aumenta el numero de wallets
        }
    }


    // Eliminar múltiples direcciones de la lista blanca
    function removeMultipleFromWhitelist(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            require(whitelist[users[i]], unicode"Un usuario no está en la lista blanca");
            whitelist[users[i]] = false;
            whitelistedCount--; //decrementa el numero de wallets
        }
    }

     function getWhitelistedCount() external view returns (uint256) {
        return whitelistedCount;
    }

    // Función para obtener el tiempo restante en segundos hasta que finalice la preventa
    function timeLeftToPresaleEnd() external view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 presaleEndTime = startTime + duration;

        if (currentTime >= presaleEndTime) {
            return 0;
        } else {
            return presaleEndTime - currentTime;
        }
    }

        
            

}