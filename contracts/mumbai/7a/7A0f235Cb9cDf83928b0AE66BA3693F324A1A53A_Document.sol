// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/*
 * @title document.do
 * @dev Control and resolve documents | Buy & sell shares | Payout rent to shareholders
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
    uint[] prices = [5,15,20,30,50,100,500,900,1500,2500,3000,4000,5000];
    address admin = 0x68c3Ca19Bb5B6cD417e3d55f0952b448b32ed10A;


//documents
    struct Data{
        address owner;
        uint commission;
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
        if(names[name].owner != 0x0000000000000000000000000000000000000000 && msg.sender != names[name].owner)
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
        require(msg.sender == names[name].owner);
        names[name].owner = owner;
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
                return prices[12];
            
            if(count == 2)
                return prices[11];
            
            if(count == 3)
                return prices[8];

            if(count == 4)
                return prices[7];

            if(count == 5)
                return prices[6];
        }

        if(alpha < 1 && numeric == 1 && special < 1)
        {
            if(count == 1)
                return prices[11];
            
            if(count == 2)
                return prices[6];
        }

        if(alpha < 1 && numeric < 1 && special == 1)
        {
            if(count == 1)
                return prices[10];
        }

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
    struct ShareholderData{
        uint8[] shares;
        uint price;
    }
    mapping(address => ShareholderData) public shareholders;
    
    struct SharesData{uint withdrawed;}
    mapping(uint => SharesData) public shares;
    uint revenue;

    function buyShares(address holder) payable public {
        
        uint sharesNumber = shareholders[holder].shares.length;

        if(sharesNumber < 1)
            revert NoShares();
        
        uint number = msg.value/shareholders[holder].price;
        require(number > 0);

        for (uint i=sharesNumber; i>number; i--){
            shareholders[msg.sender].shares.push(shareholders[holder].shares[i-1]);
            shareholders[holder].shares.pop();
        }

        (bool success) = payable(msg.sender).send(msg.value);
        if(success == false)
            revert Fail();
    }

    function getDividend() public {

        uint length = shareholders[msg.sender].shares.length;
        if(length < 1)
            revert NoShares();

        uint max = revenue/10000;
        uint amount = 0;

        for (uint i=0; i<length; i++)
        {
            uint k = shareholders[msg.sender].shares[i];
            uint withdrawed = shares[k].withdrawed;
            if(withdrawed > max)
            {
                amount += max-withdrawed;
                shares[k].withdrawed = max;
            }
        }

        if(amount < 1)
            revert LowBalance();

        (bool success) = payable(msg.sender).send(amount);
        if(success == false)
            revert Fail();
    }


//referer
    uint8 commission = 30;
    function getCommision(bytes32 name) public payable{

        if(names[name].commission < 2)
            revert LowBalance();

        uint payout = names[name].commission;
        names[name].commission = 0;

        (bool success) = payable(msg.sender).send(payout);
        if(success == false)
            revert Fail();
    }


//admin
    function setPrice(uint16 price, uint8 k) public {
        require(msg.sender == admin);
        prices[k] = price*1e18;
    }

    function setAdmin(address v) public {
        require(msg.sender == admin);
        admin = v;
    }

    function setCommission(uint8 v) public {
        require(msg.sender == admin);
        commission = v;
    }
}