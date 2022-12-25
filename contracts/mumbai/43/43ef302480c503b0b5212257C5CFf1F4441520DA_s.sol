/**
 *Submitted for verification at polygonscan.com on 2022-12-24
*/

pragma solidity >=0.7.0 <0.9.0;
contract s {
    constructor()
    {
      address  owner=tx.origin;
    }

    struct Product {
        uint ProductId;
        string product_name;
        address seller;
        uint quantity;
        uint price;
        uint rating; 
    }

    Product p1;
    Product[] Productarray;  
    function getProductId() internal returns (uint) {
    return p1.ProductId++;
    }

    function AddProducts( string memory product_name, uint quantity, uint price ) public {
        p1.seller=tx.origin;
        p1.product_name=product_name;
        p1.quantity=quantity;
        p1.price=price;
        p1.ProductId=getProductId();
        p1.rating=0;
        Productarray.push((p1));
    
    }
    function getAllProducts() public view returns (Product[] memory) {
    return Productarray;
    }


    // struct Seller {
    //     address seller_address;
    //     string seller_name;
    // }


    struct Buyer {
        address buyer_address;
        string buyer_name;
        string house_address;
        string contact_number;
    }

    struct orders {
        Product[] product_array;  
        address buyer_address;
        uint total_amount;
    }
    orders o1;
    orders[] orderarray;  
   function PlaceOrder( string memory product_name, uint quantity, uint price ) public {
        p1.seller=tx.origin;
        p1.product_name=product_name;
        p1.quantity=quantity;
        p1.price=price;
        p1.ProductId=getProductId();
        p1.rating=0;
        Productarray.push((p1));
    
    }
   

}