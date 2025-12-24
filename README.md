Linux kernel
============

There are several guides for kernel developers and users. These guides can
be rendered in a number of formats, like HTML and PDF. Please read
Documentation/admin-guide/README.rst first.

In order to build the documentation, use ``make htmldocs`` or
``make pdfdocs``.  The formatted documentation can also be read online at:

    https://www.kernel.org/doc/html/latest/

There are various text files in the Documentation/ subdirectory,
several of them using the Restructured Text markup notation.

Please read the Documentation/process/changes.rst file, as it contains the
requirements for building and running the kernel, and information about
the problems which may result by upgrading your kernel.

<img width="906" height="460" alt="스크린샷 2025-12-24 오전 11 46 43" src="https://github.com/user-attachments/assets/3ba5d6c4-7e49-4031-9e34-a1c503fa0dbb" />


# NiceSched
NiceSched utilizes AutoNUMA fault statistics to estimate the memory access locality of running processes.
It then dynamically adjusts process nice values according to their locality characteristics, enabling a memory-access-locality-aware scheduling mechanism that improves performance by prioritizing processes with higher local memory affinity.

# BUG PATCH
```We also overseved the BUG in kernel and patch. but, it not replyed```


We observe that the NUMA scan period does not change properly. The dynamic adjustment of NUMA scan period aims to find an appropriate scan period,
but I believe the current implementation does not behave as intended.
https://lore.kernel.org/all/20250404095354.311156-1-qlsdnjs236@chungbuk.ac.kr/
