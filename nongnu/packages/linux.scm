;;; Copyright © 2019 Alex Griffin <a@ajgrf.com>
;;; Copyright © 2012, 2013, 2014, 2015, 2017, 2018 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013, 2014 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2012 Nikita Karetnikov <nikita@karetnikov.org>
;;; Copyright © 2014, 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2015 Federico Beffa <beffa@fbengineering.ch>
;;; Copyright © 2015 Taylan Ulrich Bayırlı/Kammer <taylanbayirli@gmail.com>
;;; Copyright © 2015, 2017, 2018 Andy Wingo <wingo@igalia.com>
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

(define-module (nongnu packages linux)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages linux)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system trivial)
  #:use-module (nonguix licenses))

(define (linux-urls version)
  "Return a list of URLS for Linux VERSION."
  (let ((major-version (string-take version 1)))
    (list (string-append "https://www.kernel.org/pub/linux/kernel/v"
                         major-version ".x/linux-" version ".tar.xz"))))

(define (corrupt-linux freedo version hash)
  (package
    (inherit freedo)
    (name "linux")
    (version version)
    (source (origin
              (method url-fetch)
              (uri (linux-urls version))
              (sha256 (base32 hash))))
    (home-page "https://www.kernel.org/")
    (synopsis "Linux kernel with nonfree binary blobs included")
    (description
     "The unmodified Linux kernel, including nonfree blobs, for running GuixSD
on hardware which requires nonfree software to function.")))

(define-public linux
  (corrupt-linux linux-libre "5.1.5"
                 "1nvdrzrqqx5whj8sfqrxn1xmxx64595j0iz2wkzgpglprbsr17yp"))

(define-public linux-firmware
  (let ((commit "92e17d0dd2437140fab044ae62baf69b35d7d1fa")
        (revision "1"))
    (package
      (name "linux-firmware")
      (version (string-append "20190502-" revision "."
                              (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url (string-append
                            "https://git.kernel.org/pub/scm/"
                            "linux/kernel/git/firmware/linux-firmware.git"))
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "1bsgp124jhs9bbjjq0fzmdsziwx1y5aivkgpj8v56ar0y2zmrw2d"))))
      (build-system trivial-build-system)
      (arguments
       `(#:modules ((guix build utils))
         #:builder (begin
                     (use-modules (guix build utils))
                     (let ((source (assoc-ref %build-inputs "source"))
                           (fw-dir (string-append %output "/lib/firmware/")))
                       (mkdir-p fw-dir)
                       (copy-recursively source fw-dir)
                       #t))))
      (home-page
       "http://git.kernel.org/?p=linux/kernel/git/firmware/linux-firmware.git")
      (synopsis "Non-free firmware blobs for Linux")
      (description "Non-free firmware blobs for enabling support for various
hardware in the Linux kernel.")
      (license
       (nonfree
        (string-append "https://git.kernel.org/pub/scm/linux/kernel/git/"
                       "firmware/linux-firmware.git/plain/WHENCE"))))))

(define-public ath3k-firmware
  (package
   (inherit linux-firmware)
   (name "ath3k-firmware")
   (build-system trivial-build-system)
   (arguments
    `(#:modules ((guix build utils))
      #:builder (begin
                  (use-modules (guix build utils))
                  (let ((source (assoc-ref %build-inputs "source"))
                        (fw-dir (string-append %output "/lib/firmware")))
                    (mkdir-p fw-dir)
                    (copy-file (string-append source "/ath3k-1.fw")
                               (string-append fw-dir "/ath3k-1.fw"))
                    (copy-recursively (string-append source "/ar3k")
                                      (string-append fw-dir "/ar3k"))
                    #t))))
   (synopsis "Non-free firmware blobs for the ath3k Bluetooth driver")
   (description "Non-free firmware blobs for the ath3k Bluetooth driver. ath3k
is the Linux Bluetooth driver for Atheros AR3011/AR3012 Bluetooth chipsets.")
   (license
    (list
     (nonfree
      (string-append
       "https://git.kernel.org/pub/scm/linux/kernel/git/firmware"
       "/linux-firmware.git/plain/LICENCE.atheros_firmware"))
     (nonfree
      (string-append
       "https://git.kernel.org/pub/scm/linux/kernel/git/firmware"
       "/linux-firmware.git/plain/LICENSE.QualcommAtheros_ar3k"))))))

(define-public broadcom-bt-firmware
  (package
    (name "broadcom-bt-firmware")
    (version "12.0.1.710")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://dlcdnet.asus.com/pub/ASUS/wireless/"
                           "USB-BT400/DR_USB_BT400_"
                           (string-filter (char-set-complement (char-set #\.))
                                                               version)
                           "_Windows.zip"))
       (sha256
        (base32
         "1jzg1yl2hrfdh9prr2ds4rl6c69m2f8bf94m72p3rlddjvi8jj58"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils)
                  (ice-9 rdelim)
                  (ice-9 regex))
       #:builder
       (begin
         (use-modules (guix build utils)
                      (ice-9 rdelim)
                      (ice-9 regex))
         (let ((PATH (string-append (assoc-ref %build-inputs "unzip") "/bin:"
                                    (assoc-ref %build-inputs "bluez") "/bin"))
               (source (assoc-ref %build-inputs "source"))
               (firmware-dir (string-append %output "/lib/firmware/brcm/")))
           (setenv "PATH" PATH)
           (system* "unzip" source)
           (chdir "Win10_USB-BT400_DRIVERS/Win10_USB-BT400_Driver_Package/64/")
           (mkdir-p firmware-dir)
           ;; process the inf file to get the correct filenames
           (with-input-from-file "bcbtums-win8x64-brcm.inf"
             (lambda ()
               (do ((line (read-line) (read-line))
                    (devices '()))
                   ((eof-object? line) #t)
                 ;; these two `lets' are like awk patterns matching against
                 ;; records. link devices in this file with its vids and pids
                 (let ((rcrd (string-match "%=Blue(.*),.*VID_(....).*PID_(....)"
                                           line)))
                   (when rcrd
                     (set! devices
                           (assoc-set! devices (match:substring rcrd 1)
                                       `((vid . ,(match:substring rcrd 2))
                                         (pid . ,(match:substring rcrd 3)))))))
                 ;; find the hex file associated with each device, build the
                 ;; output file name
                 (let ((rcrd (string-match "\\[(RAMUSB.*)\\.CopyList\\]" line)))
                   (when rcrd
                     (let* ((key (match:substring rcrd 1))
                            ;; this happens to be 3 lines down every time
                            (hex-file (begin (read-line)
                                             (read-line)
                                             (string-drop-right (read-line) 1)))
                            (chipset (car (string-tokenize
                                           hex-file
                                           char-set:letter+digit)))
                            (vid (assoc-ref (assoc-ref devices key) 'vid))
                            (pid (assoc-ref (assoc-ref devices key) 'pid))
                            (hcd-file (string-append chipset "-"
                                                     (string-downcase vid) "-"
                                                     (string-downcase pid)
                                                     ".hcd")))
                       ;; finally convert the file, phew!
                       (system* "hex2hcd"
                                "-o" (string-append firmware-dir hcd-file)
                                hex-file)))))))))))
    (native-inputs
     `(("bluez" ,bluez)
       ("unzip" ,unzip)))
    (home-page "http://www.broadcom.com/support/bluetooth")
    (synopsis "Broadcom bluetooth firmware")
    (description
     "This package contains nonfree firmware for the following bluetooth
chipsets from Broadcom:
@itemize
@item BCM4335C0
@item BCM4350C5
@item BCM4356A2
@item BCM20702A1
@item BCM20702B0
@item BCM20703A1
@item BCM43142A0
@end itemize")
    (license (undistributable "http://www.broadcom.com/support/bluetooth"))))
