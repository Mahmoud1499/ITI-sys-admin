CREATE TABLE users (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL
);
CREATE TABLE invdata (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  customername VARCHAR(255) NOT NULL,
  date DATE NOT NULL
);

CREATE TABLE intdet (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  serial INT NOT NULL,
  prodID INT NOT NULL,
  quantity INT NOT NULL,
  unitPrice DECIMAL(10,2) NOT NULL,
  totalPrice DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unitPrice) STORED,
  intdata_id INT NOT NULL,
  FOREIGN KEY (intdata_id) REFERENCES invdata(id)
);