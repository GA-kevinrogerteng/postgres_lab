require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def dbname
  "storeadminsite"
end

def with_db
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  yield c
  c.close
end

get '/' do
  create_products_table
  create_categories_table
  create_product_categories_table
  seed_products_table
  erb :index
end
#############################################################################
# The Products machinery:

# Get the index of products
get '/products' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")

  # Get all rows from the products table.
  @products = c.exec_params("SELECT * FROM products;")
  c.close
  erb :products
end
##############################################################################
get '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")

  # Get all rows from the products table.
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :categories
end

##############################################################################
# Get the form for creating a new product
get '/products/new' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :new_product
end
##############################################################################
# POST to create a new product
post '/products' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  # Insert the new row into the products table.
  c.exec_params("INSERT INTO products (name, price, description) VALUES ($1,$2,$3)",
                  [params["name"], params["price"], params["description"]])
  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_category = params["category"].to_i
  new_product_id = c.exec_params("SELECT currval('products_id_seq');").first["currval"]
  #insert the new product id into the product_categories tabel
  c.exec_params("INSERT INTO product_categories (product_id, category_id) VALUES ($1, $2)",
                  [new_product_id], params["category"])
  c.close
  redirect "/products/#{new_product_id}"
end
##############################################################################
# Update a product
post '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")

  # Update the product.
  c.exec_params("UPDATE products SET (name, price, description) = ($2, $3, $4) WHERE products.id = $1 ",
                [params["id"], params["name"], params["price"], params["description"]])
  c.close
  redirect "/products/#{params['id']}"
end
##############################################################################
get '/categories/new' do
  erb :new_categories
end

##############################################################################
# POST to create a new Category
post '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO categories (name, description) VALUES ($1,$2)",
                  [params["name"], params["description"]])

  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_categories_id = c.exec_params("SELECT currval('categories_id_seq');").first["currval"]
  c.close
  redirect "/categories/#{new_categories_id}"
end

##############################################################################
#Update a category
post '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")

  # Update the product.
  c.exec_params("UPDATE categories SET (name, description) = ($2, $3) WHERE categories.id = $1 ",
                [params["id"], params["name"], params["description"]])
  c.close
  redirect "/categories/#{params['id']}"
end
##############################################################################
get '/products/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1", [params["id"]]).first
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :edit_product
end
##############################################################################
get '/categories/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  @categories = c.exec_params("SELECT * FROM categories WHERE categories.id = $1", [params["id"]]).first
  c.close
  erb :edit_categories
end
##############################################################################
# DELETE to delete a product
post '/products/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  c.exec_params("DELETE FROM products WHERE products.id = $1", [params["id"]])
  c.close
  redirect '/products'
end
##############################################################################
post '/categories/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  c.exec_params("DELETE FROM categories WHERE categories.id = $1", [params["id"]])
  c.close
  redirect '/categories'
end
##############################################################################
# GET the show page for a particular product
get '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1;", [params[:id]]).first
  # category_id = @product['category_id']
  # @categories = c.exec_params("SELECT * FROM categories WHERE categories.id =$1;", [category_id])
  c.close
  erb :product
end
##############################################################################
get '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  @categories = c.exec_params("SELECT * FROM categories WHERE categories.id = $1;", [params[:id]]).first
  c.close
  erb :category
end
##############################################################################
def create_products_table
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  c.exec %q{
  CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    price decimal,
    description text
  );
  }
  c.close
end
##############################################################################
def create_categories_table
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  c.exec %q{
  CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    description TEXT
  );
  }
  c.close
end
##############################################################################
def create_product_categories_table
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  c.exec %q{
  CREATE TABLE IF NOT EXISTS product_categories (
    id SERIAL PRIMARY KEY,
    product_id INTEGER,
    category_id INTEGER
  );
  }
  c.close
end

##############################################################################
def drop_products_table
  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  c.exec "DROP TABLE products;"
  c.close
end
##############################################################################
def seed_products_table
  products = [["Laser", "325", "Good for lasering."],
              ["Shoe", "23.4", "Just the left one."],
              ["Wicker Monkey", "78.99", "It has a little wicker monkey baby."],
              ["Whiteboard", "125", "Can be written on."],
              ["Chalkboard", "100", "Can be written on.  Smells like education."],
              ["Podium", "70", "All the pieces swivel separately."],
              ["Bike", "150", "Good for biking from place to place."],
              ["Kettle", "39.99", "Good for boiling."],
              ["Toaster", "20.00", "Toasts your enemies!"],
             ]

  c = PGconn.new(:host => "localhost", :dbname => "all_products")
  products.each do |p|
    c.exec_params("INSERT INTO products (name, price, description) VALUES ($1, $2, $3);", p)
  end
  c.close
end
