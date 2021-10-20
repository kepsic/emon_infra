echo ${aws_key} > ~/.env
echo ${aws_secret} >> ~/.env
sudo mkdir -p /var/www/html/
sudo sudo apt update
sudo apt -y install apache2
sudo service apache2 start
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo sudo apt -y install php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath


cat > /var/www/html/index.php << EOF
<?php
$link = mysql_connect('${mysql_host}', '${mysql_user}', '${mysql_password}');
if (!$link)
{
die('Could not connect: ' . mysql_error());
}
else
{
$selectdb = mysql_select_db("mydb");
if (!$selectdb)
{
die('Could not connect: ' . mysql_error());
}
else
{
$data = mysql_query("SELECT visits FROM counter");
if (!$data)
{
die('Could not connect: ' . mysql_error());
}
else
{
$add=mysql_query("UPDATE counter SET visits = visits+1");
if(!$add)
{
die('Could not connect: ' . mysql_error());
}
else
{
print "<table><tr><th>Visits</th></tr>";
while($value=mysql_fetch_array($data))
{
print "<tr><td>".$value['visits']."</td></tr>";
}
print "</table>";
}
}
}
}
mysql_close($link);
?>
EOF