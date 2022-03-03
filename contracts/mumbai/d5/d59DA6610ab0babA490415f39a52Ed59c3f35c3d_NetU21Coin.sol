// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact [email protected]
contract NetU21Coin is ERC20, AccessControl   {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct MyUpline{
     address u01;
     address u02;
     address u03;
     address u04;
     address u05;
     address u06;
     address u07;
     address u08;
     address u09;
     address u10;
     address u11;
     address u12;
     address u13;
     address u14;
     address u15;
     address u16;
     address u17;
     address u18;
     address u19;
     address u20;
     address u21;
    }

    mapping(uint => uint256) public totalSupplyYear; //never more than 2.1M per year
    uint256 internal totalSupplyToken; //for NETU21 Tokens
    uint public currentYear;
    uint public tokensPerMATIC = 1 * (1 ** decimals()); // token price for MATIC
    uint public tokenPrice = 1 * (1 ** decimals()); //price in Matic x 1 Netu21 token
    uint256 internal tokensSold;
    uint public tokensFaucetMint = 21000; //amount requested in faucet
    uint public percentForPublic = 99; //Percent for Public in every transaction
    uint public percentForUpline = 1; //Percent for upline

    mapping(address => MyUpline) internal usUp;
    address public WithoutMLM;
    address private TheOwner;
    mapping(address => bool) public PayToMLM;
    uint public MATICxFullTransfer = 10 * (1 ** decimals()); // MATIC amount for full transfer

    constructor() ERC20("NETU21 Coin", "NETU21") {

        totalSupplyToken = 2100000 * (10 ** decimals());

        _mint(msg.sender, totalSupplyToken);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        totalSupplyYear[2021] = totalSupplyToken;
        currentYear = 2022;
        WithoutMLM = msg.sender;

        PayToMLM[msg.sender] = false;

        TheOwner = msg.sender;
        usUp[msg.sender].u01 = msg.sender;
        usUp[msg.sender].u02 = msg.sender;
        usUp[msg.sender].u03 = msg.sender;
        usUp[msg.sender].u04 = msg.sender;
        usUp[msg.sender].u05 = msg.sender;
        usUp[msg.sender].u06 = msg.sender;
        usUp[msg.sender].u07 = msg.sender;
        usUp[msg.sender].u08 = msg.sender;
        usUp[msg.sender].u09 = msg.sender;
        usUp[msg.sender].u10 = msg.sender;
        usUp[msg.sender].u11 = msg.sender;
        usUp[msg.sender].u12 = msg.sender;
        usUp[msg.sender].u13 = msg.sender;
        usUp[msg.sender].u14 = msg.sender;
        usUp[msg.sender].u15 = msg.sender;
        usUp[msg.sender].u16 = msg.sender;
        usUp[msg.sender].u17 = msg.sender;
        usUp[msg.sender].u18 = msg.sender;
        usUp[msg.sender].u19 = msg.sender;
        usUp[msg.sender].u20 = msg.sender;
        usUp[msg.sender].u21 = msg.sender;
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
        setUpLine(to, WithoutMLM);
        totalSupplyYear[currentYear] += amount;
    }

    function faucetMint() public {
        require(balanceOf(msg.sender) == 0, "ALREADY_BALANCE");
        require(totalSupplyYear[currentYear]<210000000000000, "FAUCET_END");
        _mint(msg.sender, tokensFaucetMint);
        totalSupplyYear[currentYear] += tokensFaucetMint;
        setUpLine(msg.sender, WithoutMLM);
    }

    function transfer(address _to, uint256 amount) public virtual override returns (bool){
        require(msg.sender != _to, "BAD_DESTINATION");

        //only 99%
        uint256 _pay = (amount / 100) * percentForPublic;
        uint256 _div21 = ((amount / 100) * percentForUpline) / 42;
        
        setUpLine(_to, msg.sender);

        address _me = msg.sender;

        if (PayToMLM[_to] == false) {
            //Token mint to MLM
            _transfer(msg.sender, _to, amount);

            //MLM seller
            if ((_me != usUp[_to].u01) && (_to != usUp[_to].u01)){
                _mint(usUp[_to].u01, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u02) && (_to != usUp[_to].u02)){
                _mint(usUp[_to].u02, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u03) && (_to != usUp[_to].u03)){
                _mint(usUp[_to].u03, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u04) && (_to != usUp[_to].u04)){
                _mint(usUp[_to].u04, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u05) && (_to != usUp[_to].u05)){
                _mint(usUp[_to].u05, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u06) && (_to != usUp[_to].u06)){
                _mint(usUp[_to].u06, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u07) && (_to != usUp[_to].u07)){
                _mint(usUp[_to].u07, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u08) && (_to != usUp[_to].u08)){
                _mint(usUp[_to].u08, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u09) && (_to != usUp[_to].u09)){
                _mint(usUp[_to].u09, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u10) && (_to != usUp[_to].u10)){
                _mint(usUp[_to].u10, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u11) && (_to != usUp[_to].u11)){
                _mint(usUp[_to].u11, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u12) && (_to != usUp[_to].u12)){
                _mint(usUp[_to].u12, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u13) && (_to != usUp[_to].u13)){
                _mint(usUp[_to].u13, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u14) && (_to != usUp[_to].u14)){
                _mint(usUp[_to].u14, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u15) && (_to != usUp[_to].u15)){
                _mint(usUp[_to].u15, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u16) && (_to != usUp[_to].u16)){
                _mint(usUp[_to].u16, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u17) && (_to != usUp[_to].u17)){
                _mint(usUp[_to].u17, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u18) && (_to != usUp[_to].u18)){
                _mint(usUp[_to].u18, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u19) && (_to != usUp[_to].u19)){
                _mint(usUp[_to].u19, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u20) && (_to != usUp[_to].u20)){
                _mint(usUp[_to].u20, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_to].u21) && (_to != usUp[_to].u21)){
                _mint(usUp[_to].u21, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            //MLM buyer
            if ((_me != usUp[_me].u01) && (_to != usUp[_me].u01)){
                _mint(usUp[_me].u01, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u02) && (_to != usUp[_me].u02)){
                _mint(usUp[_me].u02, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u03) && (_to != usUp[_me].u03)){
                _mint(usUp[_me].u03, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u04) && (_to != usUp[_me].u04)){
                _mint(usUp[_me].u04, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u05) && (_to != usUp[_me].u05)){
                _mint(usUp[_me].u05, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u06) && (_to != usUp[_me].u06)){
                _mint(usUp[_me].u06, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u07) && (_to != usUp[_me].u07)){
                _mint(usUp[_me].u07, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u08) && (_to != usUp[_me].u08)){
                _mint(usUp[_me].u08, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u09) && (_to != usUp[_me].u09)){
                _mint(usUp[_me].u09, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u10) && (_to != usUp[_me].u10)){
                _mint(usUp[_me].u10, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u11) && (_to != usUp[_me].u11)){
                _mint(usUp[_me].u11, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u12) && (_to != usUp[_me].u12)){
                _mint(usUp[_me].u12, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u13) && (_to != usUp[_me].u13)){
                _mint(usUp[_me].u13, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u14) && (_to != usUp[_me].u14)){
                _mint(usUp[_me].u14, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u15) && (_to != usUp[_me].u15)){
                _mint(usUp[_me].u15, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u16) && (_to != usUp[_me].u16)){
                _mint(usUp[_me].u16, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u17) && (_to != usUp[_me].u17)){
                _mint(usUp[_me].u17, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u18) && (_to != usUp[_me].u18)){
                _mint(usUp[_me].u18, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u19) && (_to != usUp[_me].u19)){
                _mint(usUp[_me].u19, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u20) && (_to != usUp[_me].u20)){
                _mint(usUp[_me].u20, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
            if ((_me != usUp[_me].u21) && (_to != usUp[_me].u21)){
                _mint(usUp[_me].u21, _div21);
                totalSupplyYear[currentYear] += _div21;
            }
        } else {
            //receiver pay to MLM
            _transfer(_me, _to, _pay);

            //MLM Seller
            if ((_me != usUp[_to].u01) && (_to != usUp[_to].u01)){
                _transfer(_me, usUp[_to].u01, _div21);
            }

            if ((_me != usUp[_to].u02) && (_to != usUp[_to].u02)){
                _transfer(_me, usUp[_to].u02, _div21);
            }

            if ((_me != usUp[_to].u03) && (_to != usUp[_to].u03)){
                _transfer(_me, usUp[_to].u03, _div21);
            }

            if ((_me != usUp[_to].u04) && (_to != usUp[_to].u04)){
                _transfer(_me, usUp[_to].u04, _div21);
            }

            if ((_me != usUp[_to].u05) && (_to != usUp[_to].u05)){
                _transfer(_me, usUp[_to].u05, _div21);
            }

            if ((_me != usUp[_to].u06) && (_to != usUp[_to].u06)){
                _transfer(_me, usUp[_to].u06, _div21);
            }

            if ((_me != usUp[_to].u07) && (_to != usUp[_to].u07)){
                _transfer(_me, usUp[_to].u07, _div21);
            }

            if ((_me != usUp[_to].u08) && (_to != usUp[_to].u08)){
                _transfer(_me, usUp[_to].u08, _div21);
            }

            if ((_me != usUp[_to].u09) && (_to != usUp[_to].u09)){
                _transfer(_me, usUp[_to].u09, _div21);
            }

            if ((_me != usUp[_to].u10) && (_to != usUp[_to].u10)){
                _transfer(_me, usUp[_to].u10, _div21);
            }

            if ((_me != usUp[_to].u11) && (_to != usUp[_to].u11)){
                _transfer(_me, usUp[_to].u11, _div21);
            }

            if ((_me != usUp[_to].u12) && (_to != usUp[_to].u12)){
                _transfer(_me, usUp[_to].u12, _div21);
            }

            if ((_me != usUp[_to].u13) && (_to != usUp[_to].u13)){
                _transfer(_me, usUp[_to].u13, _div21);
            }

            if ((_me != usUp[_to].u14) && (_to != usUp[_to].u14)){
                _transfer(_me, usUp[_to].u14, _div21);
            }

            if ((_me != usUp[_to].u15) && (_to != usUp[_to].u15)){
                _transfer(_me, usUp[_to].u15, _div21);
            }

            if ((_me != usUp[_to].u16) && (_to != usUp[_to].u16)){
                _transfer(_me, usUp[_to].u16, _div21);
            }

            if ((_me != usUp[_to].u17) && (_to != usUp[_to].u17)){
                _transfer(_me, usUp[_to].u17, _div21);
            }

            if ((_me != usUp[_to].u18) && (_to != usUp[_to].u18)){
                _transfer(_me, usUp[_to].u18, _div21);
            }

            if ((_me != usUp[_to].u19) && (_to != usUp[_to].u19)){
                _transfer(_me, usUp[_to].u19, _div21);
            }

            if ((_me != usUp[_to].u20) && (_to != usUp[_to].u20)){
                _transfer(_me, usUp[_to].u20, _div21);
            }

            if ((_me != usUp[_to].u21) && (_to != usUp[_to].u21)){
                _transfer(_me, usUp[_to].u21, _div21);
            }

            //MLM Buyer
            if ((_me != usUp[_me].u01) && (_to != usUp[_me].u01)){
                _transfer(_me, usUp[_me].u01, _div21);
            }

            if ((_me != usUp[_me].u02) && (_to != usUp[_me].u02)){
                _transfer(_me, usUp[_me].u02, _div21);
            }

            if ((_me != usUp[_me].u03) && (_to != usUp[_me].u03)){
                _transfer(_me, usUp[_me].u03, _div21);
            }

            if ((_me != usUp[_me].u04) && (_to != usUp[_me].u04)){
                _transfer(_me, usUp[_me].u04, _div21);
            }

            if ((_me != usUp[_me].u05) && (_to != usUp[_me].u05)){
                _transfer(_me, usUp[_me].u05, _div21);
            }

            if ((_me != usUp[_me].u06) && (_to != usUp[_me].u06)){
                _transfer(_me, usUp[_me].u06, _div21);
            }

            if ((_me != usUp[_me].u07) && (_to != usUp[_me].u07)){
                _transfer(_me, usUp[_me].u07, _div21);
            }

            if ((_me != usUp[_me].u08) && (_to != usUp[_me].u08)){
                _transfer(_me, usUp[_me].u08, _div21);
            }

            if ((_me != usUp[_me].u09) && (_to != usUp[_me].u09)){
                _transfer(_me, usUp[_me].u09, _div21);
            }

            if ((_me != usUp[_me].u10) && (_to != usUp[_me].u10)){
                _transfer(_me, usUp[_me].u10, _div21);
            }

            if ((_me != usUp[_me].u11) && (_to != usUp[_me].u11)){
                _transfer(_me, usUp[_me].u11, _div21);
            }

            if ((_me != usUp[_me].u12) && (_to != usUp[_me].u12)){
                _transfer(_me, usUp[_me].u12, _div21);
            }

            if ((_me != usUp[_me].u13) && (_to != usUp[_me].u13)){
                _transfer(_me, usUp[_me].u13, _div21);
            }

            if ((_me != usUp[_me].u14) && (_to != usUp[_me].u14)){
                _transfer(_me, usUp[_me].u14, _div21);
            }

            if ((_me != usUp[_me].u15) && (_to != usUp[_me].u15)){
                _transfer(_me, usUp[_me].u15, _div21);
            }

            if ((_me != usUp[_me].u16) && (_to != usUp[_me].u16)){
                _transfer(_me, usUp[_me].u16, _div21);
            }

            if ((_me != usUp[_me].u17) && (_to != usUp[_me].u17)){
                _transfer(_me, usUp[_me].u17, _div21);
            }

            if ((_me != usUp[_me].u18) && (_to != usUp[_me].u18)){
                _transfer(_me, usUp[_me].u18, _div21);
            }

            if ((_me != usUp[_me].u19) && (_to != usUp[_me].u19)){
                _transfer(_me, usUp[_me].u19, _div21);
            }

            if ((_me != usUp[_me].u20) && (_to != usUp[_me].u20)){
                _transfer(_me, usUp[_me].u20, _div21);
            }

            if ((_me != usUp[_me].u21) && (_to != usUp[_me].u21)){
                _transfer(_me, usUp[_me].u21, _div21);
            }

        }
        return true;
    }

    /* -- MLM Functions -- */
    function setUpLine(address new_acc, address father) internal virtual returns (bool) {
        if (usUp[new_acc].u01 == address(0)) {
            PayToMLM[new_acc] = true;
            usUp[new_acc].u01 = father;
            usUp[new_acc].u02 = usUp[father].u01;
            usUp[new_acc].u03 = usUp[father].u02;
            usUp[new_acc].u04 = usUp[father].u03;
            usUp[new_acc].u05 = usUp[father].u04;
            usUp[new_acc].u06 = usUp[father].u05;
            usUp[new_acc].u07 = usUp[father].u06;
            usUp[new_acc].u08 = usUp[father].u07;
            usUp[new_acc].u09 = usUp[father].u08;
            usUp[new_acc].u10 = usUp[father].u09;
            usUp[new_acc].u11 = usUp[father].u10;
            usUp[new_acc].u12 = usUp[father].u11;
            usUp[new_acc].u13 = usUp[father].u12;
            usUp[new_acc].u14 = usUp[father].u13;
            usUp[new_acc].u15 = usUp[father].u14;
            usUp[new_acc].u16 = usUp[father].u15;
            usUp[new_acc].u17 = usUp[father].u16;
            usUp[new_acc].u18 = usUp[father].u17;
            usUp[new_acc].u19 = usUp[father].u18;
            usUp[new_acc].u20 = usUp[father].u19;
            usUp[new_acc].u21 = usUp[father].u20;
            WithoutMLM = new_acc;
            return true;
        }
        return false;
    }
    
    function getUpLine(address from, uint level) public view returns (address){
        
        if (level == 1){
            return usUp[from].u01;
        }
        if (level == 2){
            return usUp[from].u02;
        }
        if (level == 3){
            return usUp[from].u03;
        }
        if (level == 4){
            return usUp[from].u04;
        }
        if (level == 5){
            return usUp[from].u05;
        }
        if (level == 6){
            return usUp[from].u06;
        }
        if (level == 7){
            return usUp[from].u07;
        }
        if (level == 8){
            return usUp[from].u08;
        }
        if (level == 9){
            return usUp[from].u09;
        }
        if (level == 10){
            return usUp[from].u10;
        }
        if (level == 11){
            return usUp[from].u11;
        }
        if (level == 12){
            return usUp[from].u12;
        }
        if (level == 13){
            return usUp[from].u13;
        }
        if (level == 14){
            return usUp[from].u14;
        }
        if (level == 15){
            return usUp[from].u15;
        }
        if (level == 16){
            return usUp[from].u16;
        }
        if (level == 17){
            return usUp[from].u17;
        }
        if (level == 18){
            return usUp[from].u18;
        }
        if (level == 19){
            return usUp[from].u19;
        }
        if (level == 20){
            return usUp[from].u20;
        }
        if (level == 21){
            return usUp[from].u21;
        }
        return address(0);
    }

    //admin functions
    function updatePriceTokensPerMATIC(uint amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(amount > 0, "NO_VALID_AMOUNT");
        tokensPerMATIC = amount;
    }

    function updatePriceFullTransfer(uint amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(amount > 0, "NO_VALID_AMOUNT");
        MATICxFullTransfer = amount;
    }
    
    function updatePercents(uint percentUpline, uint percentPublic) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(percentUpline > 0, "NO_VALID_PERCENT_UPLINE");
        require(percentPublic > 0, "NO_VALID_PERCENT_PUBLIC");
        uint _tot = percentUpline + percentPublic;

        require(_tot == 100, "NO_VALID_100_PERCENT");
        
        percentForUpline = percentUpline;
        percentForPublic = percentPublic;
    }

    function updateCurrentYear(uint NewYear) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(NewYear == currentYear+1, "NO_VALID_YEAR");
        require(NewYear < 2032, "NO_VALID_YEAR");
        currentYear = NewYear;
    }

    function updateTokensMintFaucet(uint amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(amount > 0, "NO_VALID_AMOUNT");
        tokensFaucetMint = amount;
    }

    function SetWalletFullTranfer(address _to) public onlyRole(DEFAULT_ADMIN_ROLE){
        setUpLine(_to, WithoutMLM);
        PayToMLM[_to] = false;
    }
    
    //payable functions
    function PayForFullTranfer() external payable returns (bool){
        require(msg.value > MATICxFullTransfer);
        PayToMLM[msg.sender] = false;
        return true;
    }

    function buy() public payable returns (bool){
        require(msg.sender != address(0)); 
        require(msg.value > 0); 
        uint256 _tokensToBuy = msg.value * tokensPerMATIC;
        //require(balanceOf(TheOwner) > _tokensToBuy); 
        tokensPerMATIC -= 2100;
        //_transfer(TheOwner, msg.sender, _tokensToBuy);
        _mint(msg.sender, _tokensToBuy);
        totalSupplyYear[currentYear] += _tokensToBuy;
        setUpLine(msg.sender, WithoutMLM);
        //transfer(msg.sender, tokensToBuy); 
        tokensSold += _tokensToBuy; 
        //emit Sell(msg.sender, tokensToBuy);
        return true;
    }

    //swap functions
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "NOT_BALANCE_TO_WITHDRAW");

        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");
    }
}
//------------------------Balancer---------------------
interface PoolInterface {
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
}

interface TokenInterface {
    function balanceOf(address) external returns (uint);
    function allowance(address, address) external returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}


contract BalancerTrader {
    PoolInterface public bPool;
    TokenInterface public daiToken;
    TokenInterface public weth;
    
    constructor(PoolInterface bPool_, TokenInterface daiToken_, TokenInterface weth_) {
        bPool = bPool_;
        daiToken = daiToken_;
        weth = weth_;
    }

    function pay(uint paymentAmountInDai) public payable {
        if (msg.value > 0) {
              _swapEthForDai(paymentAmountInDai);
        } else {
              require(daiToken.transferFrom(msg.sender, address(this), paymentAmountInDai));
        }
    }
    
    function _swapEthForDai(uint daiAmount) private {
    _wrapEth(); // wrap ETH and approve to balancer pool

    PoolInterface(bPool).swapExactAmountOut(
        address(weth),
        type(uint).max, // maxAmountIn, set to max -> use all sent ETH
        address(daiToken),
        daiAmount,
        type(uint).max // maxPrice, set to max -> accept any swap prices
    );

    require(daiToken.transfer(msg.sender, daiToken.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        _refundLeftoverEth();
    }
 
    function _wrapEth() private {
        weth.deposit{ value: msg.value }();
    
    if (weth.allowance(address(this), address(bPool)) < msg.value) {
        weth.approve(address(bPool), type(uint).max);
    }
    
    }
    
    function _refundLeftoverEth() private {
        uint wethBalance = weth.balanceOf(address(this));
    
        if (wethBalance > 0) {
            // refund leftover ETH
            weth.withdraw(wethBalance);
            (bool success,) = msg.sender.call{ value: wethBalance }("");
            require(success, "ERR_ETH_FAILED");
        }
    }
    
    receive() external payable {}
}

//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract
/*
interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}



contract tokenSwap {
    
    //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private constant MATIC = 0x0000000000000000000000000000000000001010;
    

    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    
   function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
      
    //first we need to transfer the amount in tokens from the msg.sender to this contract
    //this contract will have the amount of in tokens
    IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    
    //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
    IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

    //path is an array of addresses.
    //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
    //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    if (_tokenIn == MATIC || _tokenOut == MATIC) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = MATIC;
      path[2] = _tokenOut;
    }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
    
       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above
     function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == MATIC || _tokenOut == MATIC) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = MATIC;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  
}
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}