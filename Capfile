require 'catpaws'

#generic settings
set :aws_access_key,  ENV['AMAZON_ACCESS_KEY']
set :aws_secret_access_key , ENV['AMAZON_SECRET_ACCESS_KEY']
set :ec2_url, ENV['EC2_URL']
set :ssh_options, { :user => "ubuntu", :keys=>[ENV['EC2_KEYFILE']]}
set :key, ENV['EC2_KEY']
set :key_file, ENV['EC2_KEYFILE']
set :ami, 'ami-5bab9c2f'  #EC2 eu-west-1 64bit Maverick, EBS
set :instance_type,  'c1.xlarge'
set :working_dir, '/mnt/work'
set :nhosts, 1
set :group_name, 'AMI_build'
set :snap_id, `cat SNAPID`.chomp 
set :vol_id, `cat VOLUMEID`.chomp 
set :availability_zone, 'eu-west-1a'


# Allow Capfile.local to override these settings
begin
 load("Capfile.local")
rescue Exception
end

#start EC2 instances
#cap EC2:start

# Bowtie v0.12.7
bowtie_link = 'http://downloads.sourceforge.net/project/bowtie-bio/bowtie/0.12.7/bowtie-0.12.7-linux-x86_64.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fbowtie-bio%2Ffiles%2Fbowtie%2F0.12.7%2F&ts=1287377285&use_mirror=mesh'

desc "install bowtie"
task :install_bowtie, :roles => group_name do
  run "sudo apt-get update"
  run "sudo apt-get install -y zip unzip"
  run "cd #{working_dir} && wget -Obowtie.zip #{bowtie_link}"
  run "cd #{working_dir} && unzip bowtie.zip"
  run "sudo cp #{working_dir}/bowtie*/bowtie* /usr/local/bin/"
end
before 'install_bowtie', 'EC2:start'


# R   
desc "install R on all running instances in group group_name"
#default lucid build is really old :(
task :install_r, :roles  => group_name do
  user = variables[:ssh_options][:user]
  sudo 'apt-get update'
  sudo 'apt-get -y install build-essential libxml2 libxml2-dev libcurl3 libcurl4-openssl-dev xorg-dev gfortran libreadline-dev' 

  run "cd #{working_dir} && curl http://cran.ma.imperial.ac.uk/src/base/R-2/R-2.12.1.tar.gz > R-2.12.1.tar.gz"
  run "cd #{working_dir} && tar -xvzf R-2.12.1.tar.gz"
  run "cd #{working_dir}/R-2.12.1/ && ./configure"
  run "cd #{working_dir}/R-2.12.1/ && make"
  run "cd #{working_dir}/R-2.12.1/ && sudo make install"

  upload('scripts/R_setup.R',  "#{working_dir}/R_setup.R")
  run "cd #{working_dir} && chmod +x R_setup.R"
  run "sudo Rscript #{working_dir}/R_setup.R"
end
before "install_r", "EC2:start"


#get the current mouse genome (which I already have on S3).
task :fetch_genome, :roles => group_name do
  run "cd #{working_dir}/bowtie-0.12.7/indexes && curl https://s3-eu-west-1.amazonaws.com/genome-mm9-bowtie/mm9.ebwt.zip > mm9.ebwt.zip"
  run "cd  #{working_dir}/bowtie-0.12.7/indexes && unzip -o mm9.ebwt.zip"
end 
before "fetch_genome","EC2:start"




# FastQC

fastqc_link = 'http://www.bioinformatics.bbsrc.ac.uk/projects/fastqc/fastqc_v0.7.2.zip'

desc "install_fastqc"
task :install_fastqc, :roles=>group_name do
  run "sudo apt-get update"
  run "sudo apt-get install -y default-jre"
  run "cd #{working_dir} && rm -Rf FastQC"
  run "cd #{working_dir} && curl #{fastqc_link} > fastqc.zip"
  run "cd #{working_dir} && unzip fastqc.zip"
  run "chmod +x #{working_dir}/FastQC/fastqc"
end
before 'install_fastqc','EC2:start'




# Samtools

# fetch samtools from svn
desc "get samtools"
task :get_samtools, :roles => group_name do
  sudo "apt-get -y install subversion"
  run "svn co https://samtools.svn.sourceforge.net/svnroot/samtools/trunk/samtools"
end
before "get_samtools", "EC2:start"


desc "build samtools"
task :build_samtools, :roles => group_name do
  sudo "apt-get -y install zlib1g-dev libncurses5-dev"
  run "cd /home/ubuntu/samtools && make"
end
before "build_samtools", "EC2:start"


desc "install samtools"
task :install_samtools, :roles => group_name do
  sudo "cp /home/ubuntu/samtools/samtools /usr/local/bin/samtools"
end
before "install_samtools", "EC2:start"



# Macs
macs_url ="http://liulab.dfci.harvard.edu/MACS/src/MACS-1.4.0beta.tar.gz"
macs_version = "MACS-1.4.0beta"

task :install_macs, :roles => group_name do
  sudo "apt-get install -y python"
  run "cd #{working_dir} && wget --http-user macs --http-passwd chipseq #{macs_url}"
  run "cd #{working_dir} && tar -xvzf #{macs_version}.tar.gz"
  run "cd #{working_dir}/#{macs_version} && sudo python setup.py install"
  sudo "ln -s /usr/local/bin/macs* /usr/local/bin/macs"
end
before "install_macs", 'EC2:start'

task :install_peaksplitter, :roles => group_name do
  url ='http://www.ebi.ac.uk/bertone/software/PeakSplitter_Cpp_1.0.tar.gz'
  filename = 'PeakSplitter_Cpp_1.0.tar.gz'
  bin = 'PeakSplitter_Cpp/PeakSplitter_Linux64/PeakSplitter'
  run "cd #{working_dir} && curl #{url} > #{filename}"
  run "cd #{working_dir} && tar -xvzf #{filename}"
  run "sudo cp #{working_dir}/#{bin} /usr/local/bin/PeakSplitter"
end 
before 'install_peaksplitter', 'EC2:start'


# SICER

SICER_link ="http://home.gwu.edu/~wpeng/SICER_V1.1.tgz"
desc "install sicer"
task :install_sicer, :roles => group_name do
   run "cd #{working_dir} && curl #{SICER_link} > SICER_v1.1.tgz"
   run "cd #{working_dir} && tar -xzf SICER_v1.1.tgz"

end
before 'install_sicer', 'EC2:start'


# BEDTools
#BEDTools_link = "https://github.com/arq5x/bedtools/tarball/master/arq5x-bedtools-9242fe1.tar.gz"
BEDTools_link = "https://github.com/arq5x/bedtools/tarball/master"

desc "install bedtools"
task :install_bedtools, :roles => group_name do
   run "cd #{working_dir} && curl -L #{BEDTools_link} > bedtools.tar.gz"
   run "cd #{working_dir} && tar -zxvf bedtools.tar.gz"

end
before 'install_bedtools', 'EC2:start'




