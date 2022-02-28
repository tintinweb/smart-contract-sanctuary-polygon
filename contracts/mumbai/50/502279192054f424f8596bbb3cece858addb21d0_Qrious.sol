/**
 *Submitted for verification at polygonscan.com on 2022-02-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract Qrious {
  
  struct Product {
    string id;
    string productName;
    string productImageUrl;
    string description;
    string productBrandName;
    string mrp;
  }

  mapping(string => Product) public products;
  event ProductCreated(string prodId);
  event ProductUpdated(string prodId);
  event ProductDeleted(string productId);


// Create function
  function createProduct(string memory _prodID,string memory _prodName,string memory _prodImageUrl,
  string memory _description,string memory _prodBrandNAme,string memory _mrp
  ) public {
  products[_prodID] = Product(_prodID,_prodName,_prodImageUrl,_description,_prodBrandNAme,_mrp);

  emit ProductCreated(_prodID);
}

// Update function
  function updateProduct(string memory _prodID,string memory _prodName,string memory _prodImageUrl,
  string memory _description,string memory _prodBrandNAme,string memory _mrp
  ) public {
  products[_prodID] = Product(_prodID,_prodName,_prodImageUrl,_description,_prodBrandNAme,_mrp);

  emit ProductUpdated(_prodID);
}

// Create function
  function deleteProduct(string memory _prodID  ) public {
  
  delete products[_prodID];
  emit ProductDeleted(_prodID);
}

}