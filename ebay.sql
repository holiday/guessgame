DROP SCHEMA IF EXISTS ebay CASCADE;
CREATE SCHEMA ebay; -- All tables created below live in the school schema
SET SEARCH_PATH TO ebay;  -- Otherwise we would have to talk about school.instructor, school.student, ...

DROP TABLE IF EXISTS bidder CASCADE;
CREATE TABLE bidder(
	bidderId SERIAL PRIMARY KEY,
	bname varchar(20) NOT NULL,
	address VARCHAR(50) NOT NULL,
	amount FLOAT NOT NULL DEFAULT 0
);

DROP TABLE IF EXISTS seller CASCADE;
CREATE TABLE seller (
	sellerId SERIAL PRIMARY KEY,
	sname VARCHAR(20) NOT NULL,
	sphone VARCHAR(20) NOT NULL,
	amount FLOAT NOT NULL DEFAULT 0
);

--Datatype determining whether a product is Available(A, Unavailable(U) or Sold(S)
DROP DOMAIN IF EXISTS ProductStatus CASCADE;
CREATE DOMAIN ProductStatus as CHAR(1)
    DEFAULT 'A'
	CHECK (VALUE IN ('A', 'U', 'S'));

--List of categories
DROP TABLE IF EXISTS category CASCADE;
CREATE TABLE category (
	cid SERIAL PRIMARY KEY,
	cname VARCHAR(60) NOT NULL
);

DROP TABLE IF EXISTS product CASCADE;
CREATE TABLE product (
	pid SERIAL PRIMARY KEY,
	sellerId INTEGER REFERENCES seller(sellerId) ON UPDATE CASCADE ON DELETE CASCADE,
	minbid FLOAT NOT NULL DEFAULT 0 CHECK(minbid>=0),
	description VARCHAR(50) NOT NULL,
	status ProductStatus NOT NULL,
	endDate DATE NOT NULL,
	endTime TIME NOT NULL
);

-- Link table for many-to-many categories and products
DROP TABLE IF EXISTS category_link CASCADE;
CREATE TABLE category_link (
	pid INTEGER NOT NULL REFERENCES product(pid) ON UPDATE CASCADE ON DELETE CASCADE,
	cid INTEGER NOT NULL REFERENCES category(cid) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS bid CASCADE;
CREATE TABLE bid(
	bidderId INTEGER REFERENCES bidder(bidderId) ON UPDATE CASCADE ON DELETE CASCADE,
	pid INTEGER REFERENCES product(pid) ON UPDATE CASCADE ON DELETE CASCADE,
	bidDate DATE DEFAULT current_date,
	bidTime TIME DEFAULT current_time,
	amount FLOAT NOT NULL CHECK(amount>=0),
	PRIMARY KEY (bidderId, pid, bidDate, bidTime)
);

-- Makes sure Products dont expire in the past
DROP FUNCTION IF EXISTS check_product() CASCADE;
CREATE FUNCTION check_product() RETURNS TRIGGER as $check_product$
BEGIN
	IF (NEW.endDate < current_date) THEN
		RAISE EXCEPTION 'Expiration time cannot be in the past (PID %, endDate: %, endTime: %)', NEW.pid, NEW.endDate, NEW.endTime;
	ELSIF ((NEW.endDate = current_date) AND (NEW.endTime = current_time)) THEN
		RAISE EXCEPTION 'Expiration time cannot be NOW (PID %, endDate: %, endTime: %)', NEW.pid, NEW.endDate, NEW.endTime;
	ELSE
		RETURN NEW;
	END IF;
END;
$check_product$ LANGUAGE plpgsql;

CREATE TRIGGER check_product_trigger BEFORE INSERT OR UPDATE ON product
FOR EACH ROW EXECUTE PROCEDURE check_product();


-- Trigger to check whether a user can bid on a product
-- If the product status is Available then proceed otherwise exit with message
-- If the bid amount is greater than the min bid then proceed
-- If the bid amount is greater than the previous best bid then proceed
-- A bid cannot be placed if the bidDate & bidTime have passed
-- 
DROP FUNCTION IF EXISTS check_bid() CASCADE;
CREATE FUNCTION check_bid() RETURNS TRIGGER as $check_bid$
DECLARE
	productStatus ProductStatus;
	productMinBid INT;
	prevBestBid INT;
	productBidEndDate DATE;
	productBidEndTime TIME;
BEGIN

	SELECT INTO productStatus status
	FROM product
	WHERE product.pid = NEW.pid;

	SELECT INTO productMinBid minbid
	FROM product
	WHERE product.pid = NEW.pid;

	SELECT INTO productBidEndDate endDate
	FROM product
	WHERE product.pid = NEW.pid;

	SELECT INTO productBidEndTime endTime
	FROM product
	WHERE product.pid = NEW.pid;

	SELECT INTO prevBestBid max(amount) 
	FROM product natural left join bid
	WHERE product.pid = NEW.pid;

	--Previous Best bid could be NULL, so zero out
	IF prevBestBid IS NULL THEN
		prevBestBid = 0;
	END IF;

	--check that the bid is actually valid
	IF (productStatus = 'A') THEN

		IF (NEW.amount > productMinBid) THEN
			
			IF ((NEW.bidDate < productBidEndDate) OR (NEW.bidDate = productBidEndDate AND NEW.bidTime < productBidEndTime)) THEN
				IF NEW.amount IS NOT NULL THEN
		 			IF NEW.amount > prevBestBid THEN
		 				RETURN NEW;
		 			ELSE
		 				RAISE EXCEPTION 'Amount must be larger than previous best bid (bestBid:%)', prevBestBid;
		 			END IF;
		 		ELSE
		 			RAISE EXCEPTION 'Amount cannot be NULL';
		 		END IF;
		 	ELSE 
		 		RAISE EXCEPTION 'This product expired (% @ %)', productBidEndDate, productBidEndTime;
		 	END IF;
		ELSE
			RAISE EXCEPTION 'Amount must be larger than the minimum bid of the product (%)', productMinBid;
		END IF;
	ELSE 
		RAISE EXCEPTION 'Product Unavailable/Sold (status: %)', productStatus;
	END IF;

END;
$check_bid$ LANGUAGE plpgsql;

CREATE TRIGGER check_bid_trigger BEFORE INSERT OR UPDATE ON bid
    FOR EACH ROW EXECUTE PROCEDURE check_bid();


--	Create a stored procedure called closeBids, which looks through all AVAILABLE products that are past their closing dates. 
--	This procedure should determine each such products best bid and sell the product to the bidder. 
--	This includes updating the products status, transferring appropriate amounts from bidder to seller.

DROP FUNCTION IF EXISTS closeBids() CASCADE;
CREATE FUNCTION closeBids() RETURNS void as $closeBids$
DECLARE 
	expiredRecord RECORD;
BEGIN

	FOR expiredRecord IN SELECT * FROM 
						(SELECT * FROM product 
						natural left join bid 
						natural left join (select pid, max(amount) as maxBid from bid group by pid)X
						WHERE (endDate < current_date AND status = 'A')
						OR (endDate = current_date AND endTime < current_time AND status = 'A'))Z
						WHERE amount = maxBid OR maxBid IS NULL
	LOOP
		IF (expiredRecord.maxBid IS NULL) THEN
			UPDATE product
			SET status='U'
			WHERE product.pid = expiredRecord.pid;
		ELSE

			-- Find the seller and credit him the money
			-- Find the buyer and remove the amount from his account
			-- Mark the product as SOLD
			-- IF a product has no bids then it should be marked UNAVAILABLE

			UPDATE seller 
			SET amount = amount + expiredRecord.maxBid
			where sellerId = expiredRecord.sellerId;

			UPDATE bidder
			SET amount = amount - expiredRecord.maxBid
			where bidderId = expiredRecord.bidderId;

			UPDATE product
			SET status='S'
			where product.pid = expiredRecord.pid;
		END IF;

	END LOOP;

END;
$closeBids$ LANGUAGE plpgsql;

