use strict;
use warnings;
use Cwd;
use File::Basename;

sub main {

	my $nameFile    = '';
	my $lowerName   = '';
	my $startDir = getcwd;
	
	#COMMENT (Both lines - just for testing)
	#$startDir = '/home/jarana/workspace/Pr03_MyTest/resources';
	#chdir($startDir);
	
	print "startDir:".$startDir."\n";
	
	my ($entityPath, $warFile) = @ARGV;
	
	if ( !(defined $warFile && length $warFile > 0)) {
		# If not defined Entity Path ,use this for my testing
    	$entityPath ='/home/jarana/workspace/Pr03_MyTest/src/main/java/com/learning/entities';
	}
	print "Path:" . $entityPath . "\n";

	#Obtaining Project Name
	chdir("../");
	my $rootD = getcwd;
	my $projectDir = basename($rootD);
	print "projectDir:".$projectDir, "\n";
	
	if ( !(defined $warFile && length $warFile > 0)) {
    	$warFile = $projectDir
	} 
	
	print "warFile:".$warFile."\n";
	
	#-- change dir to ../
	chdir $entityPath;
	my $dummyfiles = $entityPath."/dummy_*.txt";

	system("grep package *.java| head -1 > pack.txt");
	my $pack_file = $entityPath . "/pack.txt";

	my $content;    # content of a file to a variable
	open( my $fh, '<', $pack_file ) or die "cannot open file $pack_file";
	{
		local $/;
		$content = <$fh>;
	}
	close($fh);

	my ($entitPack) = $content =~ /(?<=package )([^\]]+)/g;
	system("rm $pack_file");
	$entitPack =~ s/;$//;     # removes last ;
	$entitPack =~ s/\R//g;    # remove linebreak from variable
	print "Entity Package:" . $entitPack . "\n";
	my $PackBase = $entitPack;

	# remove string after last .
	#$PackBase="i.like.donuts.but.only.with.tea";
	$PackBase =~ s/;$//;    # removes last ;
	 #$PackBase=~s/\.\d+$//; # <---- this does the trick (if it follows a number)
	$PackBase =~ s/\.\w+$//;    # (\w stands for word charachters)
	$PackBase =~ s/\R//g;       # remove linebreak from variable
	print "PackBase:" . $PackBase . "\n";

	chdir("../");
	my $dirBase = getcwd;

	#Creating directories
	system("mkdir repository; mkdir service; mkdir controller; mkdir config");
	print "dirBase:" . $dirBase . "\n";

	chdir($entityPath);

	my @default_files   = glob "$entityPath" . '/*';
	my $file_to_iterate = '';
	my $toFile          = '';
	#my $dummyFile       = '';
	my $type            = '';
	my $var             = '';
	my $typeVars        = '';
	my $typeValue = '';

	my $grepId         = '';
	my $grepEmbeddedId = '';
	my $grepEmbeddable = '';

	foreach $file_to_iterate (@default_files) {

		#chomp($file_to_iterate);
		if ( -f $file_to_iterate ) {
			print "+++++++++++++++++++++ Iteration ++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
			chdir($entityPath);
			print "Path:" . getcwd . "\n";
			print "File:" . $file_to_iterate . "\n";
			$nameFile = $file_to_iterate;
			$nameFile =~ s{.*/}{};         # removes path
			$nameFile =~ s{\.[^.]+$}{};    # removes extension
			$lowerName = lcfirst($nameFile);
			print "nameFile:  " . $nameFile . "   ->  ";

			$grepId = system("grep '\@Id' '$file_to_iterate'");
			$grepEmbeddedId = system("grep '\@EmbeddedId' '$file_to_iterate'");
			$grepEmbeddable = system("grep '\@Embeddable' '$file_to_iterate'");

			if ( $grepEmbeddable gt 0 ) {

				if ( $grepId eq 0 ) {			
					$typeValue =`grep -A5 "\@Id" $file_to_iterate |grep public`;
				}
				else {
					if ( $grepEmbeddedId eq 0 ) {
						$typeValue =`grep -A5 "\@EmbeddedId" $file_to_iterate |grep public`;
					}
				}

				$toFile = "dummy_" . $nameFile . ".txt";
				system("echo '$typeValue' | cut -d'(' -f1 > '$toFile'");  # Get rid of text after (

				#my $dumContent='';
				my $dummyFile = $entityPath . "/" . $toFile;
				open( my $fh, '<', $dummyFile )
				  or die "cannot open file $dummyFile";
				{
					local $/;
					$typeVars = <$fh>;
				}
				close($fh);

				$typeVars =~ s/^\s+//;
				$type = @{ [ $typeVars =~ m/\w+/g ] }[1];    #Obtain nth word

				$var = @{ [ $typeVars =~ m/\w+/g ] }[2];
				$var = substr( $var, 3 );    # Remove first 3 chars from string
				$var = ucfirst($var);

				print "type:" . $type . "\n";
				print "var:" . $var . "\n\n";

				if ( $type eq 'int' ) {
					$type = "Integer";
				}

				# REPOSITORY FILES
				#" ++++++++++++++ REPOSITORY FILES +++++++++++++++++\n";
				chdir("../repository");
				my $REPout = $nameFile . "DAO.java";
				open( OUTPUT, '>', $REPout ) or die("Can't open $REPout");
				print OUTPUT "package " . $PackBase . ".repository;\n";
				print OUTPUT "import java.util.List;\n\n";
				print OUTPUT "import org.springframework.data.jpa.repository.JpaRepository;\n";
				print OUTPUT "import org.springframework.stereotype.Repository;\n\n";
				print OUTPUT "import "
				  . $entitPack . "."
				  . $nameFile . ";" . "\n\n";
				print OUTPUT "\@Repository(\"" . $lowerName . "DAO\")\n";
				print OUTPUT "public interface ". $nameFile. "DAO extends JpaRepository<". $nameFile . ", ". $type. "> {\n\n";
				print OUTPUT "\/\/\t List<". $nameFile. "> findBy-ReplaceFIELD(TYPE FIELD);\n\n";
				print OUTPUT "}\n";		
				close(OUTPUT);
				print "** RepoFile:" . getcwd . "/" . $REPout . "\n";
				

				# SERVICE FILES
				chdir("../service");
				my $SERVout = $nameFile . "Service.java";

				open( OUTPUT, '>', $SERVout ) or die("Can't open $REPout");
				print OUTPUT "package " . $PackBase . ".service;\n";

				print OUTPUT "import java.util.List;\n\n";
				print OUTPUT "import " . $entitPack . "." . $nameFile . ";\n";
				print OUTPUT "public interface " . $nameFile . "Service {\n";
				print OUTPUT "\tpublic List<" . $nameFile . "> findAll();\n";
				print OUTPUT "\tpublic ". $nameFile. " findOne(".$type." ".$var.");\n";
				print OUTPUT "\/\/\tpublic List<". $nameFile. "> findBy-ReplaceFIELD(TYPE FIELD);\n";
				print OUTPUT "\tpublic void create (". $nameFile . " ". $lowerName . ");\n";
				print OUTPUT "\tpublic void update (". $nameFile . " ". $lowerName . ");\n";
				print OUTPUT "\tpublic void delete (". $nameFile . " ". $lowerName . ");\n";
				print OUTPUT "}\n";
				close(OUTPUT);
				print "** ServFile:" . getcwd . "/" . $SERVout . "\n";

				# SERVICE IMPL
				my $SERVImpOut = $nameFile . "ServiceImpl.java";

				open( OUTPUT, '>', $SERVImpOut ) or die("Can't open $REPout");
				print OUTPUT "package " . $PackBase . ".service;\n";
				print OUTPUT "import java.util.List;\n\n";
				print OUTPUT "import org.springframework.beans.factory.annotation.Autowired;\n";
				print OUTPUT "import org.springframework.stereotype.Service;\n";
				print OUTPUT "import org.springframework.transaction.annotation.Transactional;\n\n";
				print OUTPUT "import " . $entitPack . "." . $nameFile . ";\n";
				print OUTPUT "import ". $PackBase. ".repository" . ".". $nameFile. "DAO;\n\n";
				print OUTPUT "\@Transactional\n";
				print OUTPUT "\@Service(\"" . $lowerName . "Service\")\n";
				print OUTPUT "public class ". $nameFile. "ServiceImpl implements ". $nameFile. "Service {\n\n";
				print OUTPUT "\t\@Autowired\n";
				print OUTPUT "\tprivate ". $nameFile . "DAO ". $lowerName. "DAO;\n\n";
				print OUTPUT "\tpublic List<" . $nameFile . "> findAll() {\n";
				print OUTPUT "\t\tList<". $nameFile. "> list". $nameFile . " = ". $lowerName. "DAO.findAll();\n";
				print OUTPUT "\t\treturn list" . $nameFile . ";\n";
				print OUTPUT "\t}\n\n";

				print OUTPUT "\tpublic ". $nameFile. " findOne(".$type." ".$var.") {\n";
				print OUTPUT "\t\treturn ". $lowerName. "DAO.findOne(".$var.");\n";
				print OUTPUT "\t}\n\n";

				print OUTPUT "\/\/\tpublic List<". $nameFile. "> findBy-ReplaceFIELD(TYPE FIELD) {\n";
				print OUTPUT "\/\/\t\treturn ". $lowerName. "DAO.findBy-ReplaceFIELD(FIELD);\n";
				print OUTPUT "\/\/\t}\n\n";
				print OUTPUT "\tpublic void create (". $nameFile . " ". $lowerName . ") {\n";
				print OUTPUT "\t\t". $lowerName. "DAO.save(". $lowerName . ");\n";
				print OUTPUT "\t}\n\n";
				print OUTPUT "\tpublic void update (". $nameFile . " ". $lowerName . ") {\n";
				print OUTPUT "\t\t". $lowerName. "DAO.save(". $lowerName . ");\n";
				print OUTPUT "\t}\n\n";
				print OUTPUT "\tpublic void delete (". $nameFile . " ". $lowerName . ") {\n";
				print OUTPUT "\t\t" . $lowerName. "DAO.delete(". $lowerName . ");\n";
				print OUTPUT "\t}\n\n";
				print OUTPUT "}\n";
				close(OUTPUT);
				print "** ServImplFile:" . getcwd . "/" . $SERVImpOut . "\n";

				# CONTROLLER
				chdir("../controller");
				my $ContrOut = $nameFile . "Controller.java";
				open( OUTPUT, '>', $ContrOut ) or die("Can't open $ContrOut");
				print OUTPUT "package " . $PackBase . ".controller;\n";
				print OUTPUT "import java.util.List;\n\n";
				print OUTPUT "import org.springframework.beans.factory.annotation.Autowired;\n";
				print OUTPUT "import org.springframework.http.MediaType;\n";
				print OUTPUT "import org.springframework.stereotype.Controller;\n";
				print OUTPUT "import org.springframework.ui.Model;\n";
				print OUTPUT "import org.springframework.web.bind.annotation.PathVariable;\n";
				print OUTPUT "import org.springframework.web.bind.annotation.RequestBody;\n";
				print OUTPUT "import org.springframework.web.bind.annotation.RequestMapping;\n";
				print OUTPUT "import org.springframework.web.bind.annotation.RequestMethod;\n";
				print OUTPUT "import org.springframework.web.bind.annotation.ResponseBody;\n\n";
				print OUTPUT "import " . $entitPack . "." . $nameFile . ";\n";
				print OUTPUT "import ". $PackBase. ".service.". $nameFile. "Service;\n\n";
				print OUTPUT "\@Controller\n";
				print OUTPUT "\@RequestMapping(\"\/" . lc($lowerName) . "\")\n";
				print OUTPUT "public class " . $nameFile . "Controller { \n\n";
				print OUTPUT "\t\@Autowired\n";
				print OUTPUT "\tprivate ". $nameFile. "Service ". $lowerName. "Service;\n\n";
				print OUTPUT "\t\@RequestMapping(method = RequestMethod.GET)\n";
				print OUTPUT "\t\@ResponseBody\n";
				print OUTPUT "\tpublic List<" . $nameFile . "> findAll() {\n";
				print OUTPUT "\t\treturn ". $lowerName. "Service.findAll();\n";
				print OUTPUT "\t}\n\n";
				print OUTPUT "\t\@RequestMapping(value = \"\/{id}\", method = RequestMethod.GET)\n";
				print OUTPUT "\t\@ResponseBody\n";
				print OUTPUT "\tpublic ". $nameFile. " find(\@PathVariable(\"id\") ".$type." ".$var.") {\n";
				print OUTPUT "\t\treturn ". $lowerName. "Service.findOne(".$var.");\n";
				print OUTPUT "\t}\n\n";

				print OUTPUT "\/\/\t\@RequestMapping(value = \"\/WISHED_FIELD_NAME\/{FIELD}\", method = RequestMethod.GET)\n";
				print OUTPUT "\/\/\t\@ResponseBody\n";
				print OUTPUT "\/\/\tpublic List<". $nameFile. "> findBy-ReplaceFIELD(\@PathVariable(\"FIELD\") TYPE FIELD) {\n";
				print OUTPUT "\/\/\t\treturn ". $lowerName. "Service.findBy-ReplaceFIELD(FIELD);\n";
				print OUTPUT "\/\/\t}\n\n";
				print OUTPUT "\t\@RequestMapping(value = \"\/add". "\", method = RequestMethod.POST, consumes = MediaType.APPLICATION_JSON_VALUE)\n";
				print OUTPUT "\t\@ResponseBody\n";
				print OUTPUT "\tpublic void create(\@RequestBody ". $nameFile . " ". $lowerName . ") {\n";
				print OUTPUT "\t\t". $lowerName. "Service.create(". $lowerName . ");\n";
				print OUTPUT "\t}\n\n";
				print OUTPUT "\t\@RequestMapping(value = \"\/edit". "\", method = RequestMethod.PUT, consumes = MediaType.APPLICATION_JSON_VALUE)\n";
				print OUTPUT "\t\@ResponseBody\n";
				print OUTPUT "\tpublic void update(\@RequestBody ". $nameFile . " ". $lowerName . ") {\n";
				print OUTPUT "\t\t". $lowerName. "Service.update(". $lowerName . ");\n";
				print OUTPUT "\t}\n\n";
				print OUTPUT "\t\@RequestMapping(value = \"\/delete". "\", method = RequestMethod.DELETE)\n";
				print OUTPUT "\t\@ResponseBody\n";
				print OUTPUT "\tpublic void delete(\@RequestBody ". $nameFile . " ". $lowerName . ") {\n";
				print OUTPUT "\t\t". $lowerName. "Service.delete(". $lowerName . ");\n";
				print OUTPUT "\t}\n\n";
				print OUTPUT "}\n";
				close(OUTPUT);
				print "** ControllerFile:" . getcwd . "/" . $ContrOut . "\n";

			}
			else {
				print "$nameFile -> \@Embeddable Type\n";
				print "No need to iterate\n";
			}
			

		}   
	}    

	

	# Create HelloController

	chdir("../controller");
	$nameFile = "Hello";
	my $ContrHello = "HelloController.java";

	open( OUTPUT, '>', $ContrHello ) or die("Can't open $ContrHello");

	print OUTPUT "package " . $PackBase . ".controller;\n";
	print OUTPUT "import org.springframework.stereotype.Controller;\n";
	print OUTPUT "import org.springframework.ui.Model;\n";
	print OUTPUT "import org.springframework.web.bind.annotation.RequestMapping;\n";
	print OUTPUT "import org.springframework.web.bind.annotation.ResponseBody;\n\n";
	print OUTPUT "\@Controller\n";
	print OUTPUT "\@RequestMapping(value = \"\/\")\n";
	print OUTPUT "public class " . $nameFile . "Controller { \n\n";
	print OUTPUT "\t\@RequestMapping\n";
	print OUTPUT "\t\@ResponseBody\n";
	print OUTPUT "\tpublic String sayHello(Model model) {\n";
	print OUTPUT "\t\tmodel.addAttribute(\"greeting\",\"Hello World from Web Services\");\n";
	print OUTPUT "\t\treturn \"helloWorld\";\n";
	print OUTPUT "\t}\n\n";
	print OUTPUT "}\n\n";
	
	print "** ControllerFile:" . getcwd . "/" . $ContrHello . "\n\n";
	
	# Erasing dummy files
	unlink glob($dummyfiles);
	
	# Go to resources directory ($startDir)
	chdir($startDir);
	
	
	#  update package names and copy Config files
	print "Getting Config Files\n";
	`sed -i 's/MyPaCkAgE/'$PackBase'/g' config/Initializer.java`;
	`sed -i 's/MyPaCkAgE/'$PackBase'/g' config/WebAppConfig.java`;
	
	# cd ../src/main/java/com/learning/config/
	`cp config/Initializer.java '$dirBase'/config/`;
	`cp config/WebAppConfig.java '$dirBase'/config/`;

	
	# update pom.xml and copy
	`sed -i 's/GrOuPID/'$PackBase'/g' config/pom.xml`;
	`sed -i 's/PrOjEcTNAME/'$projectDir'/g' config/pom.xml`;
	`sed -i 's/FiNaLNAME/'$warFile'/g' config/pom.xml`;
	
	`cp config/pom.xml ../`;
	
	
	# applications.properties
	
	`sed -i 's/MyPaCkAgE/'$PackBase'/g' config/application.properties`;
	
	# if directory does not exists, create it
	chdir("../src/main");
	if (!-d "resources") {
   		system("mkdir resources");
	} 
	
	chdir($startDir);
	print"myActualDir:".getcwd."\n";
	`cp config/application.properties ../src/main/resources/`;
	
	# Copying logback file
	`cp config/logback.xml ../src/main/resources/`;
	
	print "\n*** NOTE.- Don't forget to set up JDBC DB Connection settings at\n";
	print "    src/main/resources/application.properties\n\n";
	
	
	
	#create jsp folder in WEB-INF
	# from /home/jarana/workspace/Pr03_MyTest/src/main/webapp/WEB-INF, mkdir jsp
	#cp index.jsp /home/jarana/workspace/Pr03_MyTest/src/main/webapp/WEB-INF/jsp
	
	# copy/paste jsp web page
	
	#  <groupId>GrOuPID</groupId>
	#  <groupId>GrOuPID</groupId>
	#  <finalName>FiNaLNAME</finalName>
	# hello world page
	

}    # main

main();
