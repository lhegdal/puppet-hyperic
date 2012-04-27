class hyperic::client inherits hyperic {

  $hyperic_agent_source = "hyperic-hq-agent-${hyperic_version}-${architecture}-${kernel}.tar.gz"
  $hyperic_server_ip = hiera("hyperic_server_ip", "127.0.0.1")
  $hyperic_hq_user = hiera("hyperic_hq_user", "hqadmin")
  $hyperic_hq_pass = hiera("hyperic_hq_pass", "hqadmin")

  file { "/home/hyperic/src":
    owner   => hyperic,
    group   => admin,
    mode    => 755,
    ensure  => directory,
  }

  file { "/home/hyperic/src/hyperic-hq-agent.tar.gz":
    owner   => hyperic,
    group   => admin,
    mode    => 644,
    source  => "puppet:///modules/hyperic/${hyperic_agent_source}",
    notify  => Exec["hyperic-agent-install"],
    require => File["/home/hyperic/src"],
  }

  file { "/etc/init.d/hyperic-agent":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet:///modules/hyperic/hyperic-agent",
  }

  file { "/etc/default/hyperic-agent":
    owner   => root,
    group   => root,
    mode    => 644,
    content => template("hyperic/hyperic-agent.default.erb"),
  }

  exec { "hyperic-agent-install":
    path        => "/bin:/usr/bin:/usr/local/bin",
    cwd         => "/home/hyperic/src",
    command     => "tar -xzf hyperic-hq-agent.tar.gz && chown -R hyperic:admin /home/hyperic/src/hyperic-hq-agent-${hyperic_version}",
    require     => File["/home/hyperic/src/hyperic-hq-agent.tar.gz"],
    refreshonly => true,
  }
  
  file { "/home/hyperic/src/hyperic-hq-agent-${hyperic_version}/conf/agent.properties":
    owner       => hyperic,
    group       => hyperic,
    mode        => 644,
    content     => template("hyperic/agent.properties.erb"),
    require     => Exec["hyperic-agent-install"],
  }
  
  service { "hyperic-agent":
    ensure    => running,
    require   => [ File["/etc/init.d/hyperic-agent"], File["/home/hyperic/src/hyperic-hq-agent-${hyperic_version}/conf/agent.properties"] ],
  }
}

class hyperic::client::mongodb inherits hyperic::client {

  exec { "hyperic-agent-mongodb":
    path    => "/bin:/usr/bin:/usr/local/bin",
    cwd     => "/home/hyperic/src/hyperic-hq-agent-${hyperic_version}/bundles/agent-${hyperic_version}/pdk/plugins",
    command => "wget --no-check-certificate https://github.com/ClarityServices/hyperic-mongodb/raw/master/mongodb-plugin.xml && chown hyperic:hyperic mongodb-plugin.xml",
    creates => "/home/hyperic/src/hyperic-hq-agent-${hyperic_version}/bundles/agent-${hyperic_version}/pdk/plugins/mongodb-plugin.xml",
    notify      => Service["hyperic-agent"],
  }

}

class hyperic::client::nginx inherits hyperic::client {

  exec { "hyperic-agent-nginx":
    path    => "/bin:/usr/bin:/usr/local/bin",
    cwd     => "/home/hyperic/src/hyperic-hq-agent-${hyperic_version}/bundles/agent-${hyperic_version}/pdk/plugins",
    command => "wget http://nginx-hyperic.googlecode.com/svn/trunk/nginx-plugin.xml && chown hyperic:hyperic nginx-plugin.xml",
    creates => "/home/hyperic/src/hyperic-hq-agent-${hyperic_version}/bundles/agent-${hyperic_version}/pdk/plugins/nginx-plugin.xml",
    notify      => Service["hyperic-agent"],
  }

}

class hyperic::client::varnish inherits hyperic::client {

  package { "libconfig-ini-simple-perl":
    ensure  => installed,
  }

  file { "/home/hyperic/src/hyperic-hq-agent-${hyperic_version}/bundles/agent-${hyperic_version}/pdk/plugins/varnish-plugin.xml":
    owner       => hyperic,
    group       => hyperic,
    mode        => 644,
    source      => "puppet:///modules/hyperic/varnish-plugin.xml",
    notify      => Service["hyperic-agent"],
  }

  file { "/home/hyperic/varnishstat.pl":
    owner       => root,
    group       => root,
    mode        => 755,
    source      => "puppet:///modules/hyperic/varnishstat.pl",
    require     => Package["libconfig-ini-simple-perl"],
  }

}