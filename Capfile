require 'catpaws'

#generic settings
set :aws_access_key,  ENV['AMAZON_ACCESS_KEY']
set :aws_secret_access_key , ENV['AMAZON_SECRET_ACCESS_KEY']
set :ec2_url, ENV['EC2_URL']
set :ssh_options, { :user => "ubuntu", :keys=>[ENV['EC2_KEYFILE']]}
set :key, ENV['EC2_KEY']
set :key_file, ENV['EC2_KEYFILE']
set :ami, `cat AMIID`.chomp
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


# Note - #{working_dir} is under /mnt and will *not* be included when you make your AMI.
# This means its a good place to download stuff to and build it but you need to make sure
# that you've copied all binaries, libraries, docs etc that you want in your final AMI to
# appropriate places on the file system


desc "install "
task :install_packages, :roles => group_name do
  sudo "apt-get update"
  sudo "apt-get install -y zip unzip p7zip-full"
  sudo 'apt-get -y install build-essential libxml2 libxml2-dev libcurl3 libcurl4-openssl-dev xorg-dev gfortran libreadline-dev'
  sudo "apt-get install -y default-jre"
  sudo "apt-get -y install subversion"
  sudo "apt-get -y install zlib1g-dev libncurses5-dev"
  sudo "apt-get install -y python python-numpy python-scipy"
end

before :install_packages, "EC2:start"


# Bowtie v0.12.7
bowtie_link = 'http://downloads.sourceforge.net/project/bowtie-bio/bowtie/0.12.7/bowtie-0.12.7-linux-x86_64.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fbowtie-bio%2Ffiles%2Fbowtie%2F0.12.7%2F&ts=1287377285&use_mirror=mesh'

desc "install bowtie"
task :install_bowtie, :roles => group_name do
  run "cd #{working_dir} && wget -Obowtie.zip #{bowtie_link}"
  run "cd #{working_dir} && unzip bowtie.zip"
  run "sudo cp #{working_dir}/bowtie*/bowtie* /usr/local/bin/"
end
before 'install_bowtie', 'EC2:start'


# R   
desc "install R on all running instances in group group_name"
task :install_r, :roles  => group_name do
  user = variables[:ssh_options][:user]
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


# FastQC

fastqc_link = 'http://www.bioinformatics.bbsrc.ac.uk/projects/fastqc/fastqc_v0.7.2.zip'

desc "install_fastqc"
task :install_fastqc, :roles=>group_name do
  sudo "mkdir -p /opt/fastqc"
  sudo "chown ubuntu:ubuntu /opt/fastqc"

  run "rm -rf /opt/fastq/*"
  run "rm -rf #{working_dir}/FastQC"

  run "cd #{working_dir} && curl #{fastqc_link} > fastqc.zip"
  run "cd #{working_dir} && unzip fastqc.zip"
  run "chmod +x #{working_dir}/FastQC/fastqc"
 
  run "cp -R #{working_dir}/FastQC/* /opt/fastqc/"
  sudo "ln -s /opt/fastqc/fastqc /usr/local/bin/fastqc"

 
end
before 'install_fastqc','EC2:start'




# Samtools

# fetch samtools from svn
desc "install samtools"
task :install_samtools, :roles => group_name do
  run "cd #{working_dir} && svn co https://samtools.svn.sourceforge.net/svnroot/samtools/trunk/samtools"
  run "cd #{working_dir}/samtools && make"
  sudo "cp #{working_dir}/samtools/samtools /usr/local/bin/samtools"
  sudo "cp #{working_dir}/samtools/bcftools/bcftools /usr/local/bin/bcftools"
  sudo "cp #{working_dir}/samtools/bcftools/vcfutils.pl /usr/local/bin/vcfutils.pl"
end
before "install_samtools", "EC2:start"



# Macs
macs_url ="http://liulab.dfci.harvard.edu/MACS/src/MACS-1.4.0beta.tar.gz"
macs_version = "MACS-1.4.0beta"

task :install_macs, :roles => group_name do
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
  run "cd #{working_dir} && curl #{SICER_link} > SICER_V1.1.tgz"
  run "cd #{working_dir} && tar -xzf SICER_V1.1.tgz"
  run "cd #{working_dir}/SICER_V1.1/SICER && chmod +x *.sh"
  sudo "cp -R #{working_dir}/SICER_V1.1/SICER /opt/SICER"
  sudo "chown ubuntu:ubuntu /opt/SICER"
  run 'cd /opt/SICER && perl -pi -e "s/^PATHTO.*/PATHTO=\\/opt/" *.sh'
  sudo "ln -s /opt/SICER/SICER.sh /usr/local/bin/SICER"
end
before 'install_sicer', 'EC2:start'


# BEDTools
BEDTools_link = "https://github.com/arq5x/bedtools/tarball/master"

desc "install bedtools"
task :install_bedtools, :roles => group_name do
#  run "cd #{working_dir} && curl -L #{BEDTools_link} > bedtools.tar.gz"
#  run "cd #{working_dir} && tar -zxvf bedtools.tar.gz" 

  bed_dir =  capture "ls -d #{working_dir}/*bedtools*"
  bed_dir = bed_dir.split("\n").reject{|f| f.match(/.*gz$/) }[0]

  run "cd #{bed_dir} && make"
  sudo "cp #{bed_dir}/bin/* /usr/local/bin/"
end
before 'install_bedtools', 'EC2:start'






