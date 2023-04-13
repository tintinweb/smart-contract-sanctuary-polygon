// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/*
 * @title document.do
 * @dev Control and resolve documents | Buy & sell shares | Payout Dividend | Payout commision
 */

error Unauthorized();
error LowBalance();
error LowAmount();
error NameTaken();
error NoShares();
error Fail();
error InvalidName();

contract Document {

//common
    uint[] prices = [1000000000000000000,2000000000000000000,5000000000000000000,10000000000000000000,20000000000000000000,50000000000000000000,20000000000000000000,100000000000000000000,500000000000000000000,500000000000000000000,1500000000000000000000,2500000000000000000000];
    address admin = 0xBc0566c559937babACA00E8a41c4D4c0eDE8F2E7;


//documents
    struct Data{
        address owner;
        uint commission;
        uint price;
        mapping(bytes32 => string) content;
    }
    mapping(bytes32 => Data) private names;
    
    function getDocument(bytes32 name, bytes32 path) view public returns (string memory) {
        
        string memory owned = '0';
        
        if(names[name].owner != 0x0000000000000000000000000000000000000000)
            owned = '1';

        return string.concat(owned, names[name].content[path]);
    }

    function editDocument(bytes32 name, string calldata content, bytes32 path) public {
        if(names[name].owner != 0x0000000000000000000000000000000000000000 && msg.sender != names[name].owner || path != 0x0000000000000000000000000000000000000000000000000000000000000000 && msg.sender != names[name].owner)
            revert Unauthorized();

        names[name].content[path] = content;
    }

    function buyDocument(bytes32 name, string calldata content, bytes32 referer) payable public{
        if(names[name].owner != 0x0000000000000000000000000000000000000000)
            revert NameTaken();

        uint amount = msg.value;

        if(amount < priceDocument(name))
            revert LowAmount();

        if(amount > 0)
        {
            if(commission > 0 && names[referer].owner != 0x0000000000000000000000000000000000000000)
            {
                uint com = (amount*commission)/100;
                names[referer].commission += com;
                amount = amount-com;
            }
            revenue += amount;
        }

        names[name].owner = msg.sender;
        names[name].content[0x0000000000000000000000000000000000000000000000000000000000000000] = content;
    }

    function ownerDocument(bytes32 name) view public returns (address) {
        return names[name].owner;
    }

    function transferDocument(bytes32 name, address owner) public {
        if(msg.sender != names[name].owner)
            revert Unauthorized();

        names[name].owner = owner;
    }

    function buyDocumentFromOwner(bytes32 name) payable public {
        if(names[name].price < 1)
            revert Unauthorized();

        if(msg.value < names[name].price)
            revert LowBalance();

        (bool success) = payable(names[name].owner).send(msg.value);
        
        names[name].owner = msg.sender;
        
        if(success == false)
            revert Fail();
    }

    function sellDocument(bytes32 name, uint price) public {
        if(msg.sender != names[name].owner)
            revert Unauthorized();

        names[name].price = price;
    }

    function priceDocument(bytes32 name) view public returns (uint) {
        
        uint8 alpha = 0;
        uint8 numeric = 0;
        uint8 special = 0;
        uint8 count = 0;

        for (uint8 i=0; i<32; i++)
        {
            if(uint8(name[i]) == 0)
            {
                if(count > 0)
                    break;
                else
                    revert InvalidName();
            }
                
            if((uint8(name[i]) == 32 && (i == 0 || uint8(name[i+1]) == 0 || uint8(name[i-1]) == 32)) || uint8(name[i]) == 35 || uint8(name[i]) == 47 || uint8(name[i]) == 46 || (uint8(name[i]) > 8 && 12 > uint8(name[i])) || uint8(name[i]) == 34 || uint8(name[i]) == 39 || uint8(name[i]) == 92)
                revert InvalidName();

            if(uint8(name[i]) > 47 && uint8(name[i]) < 58)
                ++numeric;
            else if(uint8(name[i]) > 96 && uint8(name[i]) < 123)
                ++alpha;
            else
                ++special;

            ++count;
        }

        if(count > 10)
            return prices[0];

        if(alpha > 0 && numeric < 1 && special < 1)
        {
            if(count == 1)
                return prices[11];
            
            if(count == 2)
                return prices[10];
            
            if(count == 3)
                return prices[8];

            if(count == 4)
                return prices[7];

            if(count == 5)
                return prices[6];
        }

        if(alpha < 1 && numeric > 0 && special < 1)
        {
            if(count == 1)
                return prices[10];
            
            if(count == 2)
                return prices[7];
        }

        if(count == 1 && special > 0)
            return prices[9];

        if(count == 2)
           return prices[5];

        if(count == 3)
           return prices[4];

        if(count == 4)
           return prices[3];

        if(count < 8)
           return prices[2];

        return prices[1];
    }


//shareholders
    constructor(){
        for(uint16 i=1;i<5001;i++)
            shareholders[admin].shares.push(i);
    }

    struct ShareholderData{
        uint16[] shares;//owned share ID's
        uint sell;//number of shares for sale
        uint price;//price for 1 share
    }
    mapping(address => ShareholderData) public shareholders;
    
    struct ShareData{uint balance;}
    mapping(uint16 => ShareData) public share;//share[share ID]

    //shares are grouped in groups of 10
    struct RangesData{uint paid;}
    mapping(uint8 => RangesData) public ranges;
    
    uint revenue;

    function revenueToBalance(uint8 range) public{
        uint amount = (revenue/5000)-ranges[range].paid;

        if(amount < 9)
            return;

        for(uint8 share_id = (range-9); share_id <= range; share_id++)
            share[share_id].balance += amount;

        ranges[range].paid += amount*10;
    }

    function revenueToBalanceAll() public{
        for(uint8 range = 10; range < 5001;)
        {
            revenueToBalance(range);
            range += 10;
        }
    }

    function getDividend(uint16 start, uint16 max) public {

        uint length = shareholders[msg.sender].shares.length;

        if(length < 1)
            revert NoShares();

        if(length > max)
            length = max;

        uint amount;

        for (uint i=start; i<length; i++)
        {
            uint16 share_id = shareholders[msg.sender].shares[i];
            amount += share[share_id].balance;
            share[share_id].balance = 0;
        }

        if(amount < 1)
            revert LowBalance();

        (bool success) = payable(msg.sender).send(amount);
        if(success == false)
            revert Fail();
    }

    function buyShares(address holder) payable public {
        
        uint sharesNumber = shareholders[holder].shares.length;

        if(sharesNumber < 1)
            revert NoShares();
        
        uint number = msg.value/shareholders[holder].price;
        require(number > 0 && number <= shareholders[holder].sell, "Not enough shares 4 this price");

        for (uint i=sharesNumber; i>sharesNumber-number; i--){
            shareholders[msg.sender].shares.push(shareholders[holder].shares[i-1]);
            shareholders[holder].shares.pop();
        }

        shareholders[holder].sell -= number;

        (bool success) = payable(holder).send(msg.value);
        if(success == false)
            revert Fail();
    }

    function shareNumber(address holder) view public returns (uint){
        return shareholders[holder].shares.length;
    }

    function sellShares(uint price, uint8 nr) public {
        shareholders[msg.sender].price = price;
        shareholders[msg.sender].sell = nr;
    }

//referer
    uint8 commission = 0;
    function getCommision(bytes32 name) public payable{
 
        if(names[name].commission < 1)
            revert LowBalance();

        if(names[name].owner != msg.sender)
            revert Unauthorized();

        uint payout = names[name].commission;
        names[name].commission = 0;

        (bool success) = payable(msg.sender).send(payout);
        if(success == false)
            revert Fail();
    }

    function currentCommission() view public returns (uint8) {
        return commission;
    }


//admin
    function adminPrice(uint price, uint8 k) public {
        if(msg.sender != admin)
            revert Unauthorized();

        prices[k] = price;
    }

    function adminAddress(address v) public {
        if(msg.sender != admin)
            revert Unauthorized();

        admin = v;
    }

    function adminCommission(uint8 v) public {
        if(msg.sender != admin)
            revert Unauthorized();

        commission = v;
    }
}